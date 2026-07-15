#!/usr/bin/env ruby
# frozen_string_literal: true

# Populates the editable App Store Connect record for Maxi's Mighty Mindgames.
# It intentionally never creates an App Store version submission or submits for review.

require "base64"
require "digest"
require "json"
require "net/http"
require "openssl"
require "uri"

class AppStoreConnectError < StandardError; end

class AppStoreConnectClient
  BASE_URL = "https://api.appstoreconnect.apple.com"

  def initialize(key_id:, issuer_id:, key_path:)
    @key_id = key_id
    @issuer_id = issuer_id
    @private_key = OpenSSL::PKey::EC.new(File.read(key_path))
  end

  def get(path, allow: [])
    request(:get, path, allow: allow)
  end

  def post(path, body)
    request(:post, path, body: body)
  end

  def patch(path, body)
    request(:patch, path, body: body)
  end

  def delete(path)
    request(:delete, path)
  end

  def collection(path)
    resources = []
    included = []
    next_path = path

    while next_path
      response = get(next_path)
      resources.concat(response.fetch("data"))
      included.concat(response.fetch("included", []))
      next_path = response.dig("links", "next")
    end

    { "data" => resources, "included" => included }
  end

  def upload(operation, bytes)
    uri = URI(operation.fetch("url"))
    request_class = Net::HTTP.const_get(operation.fetch("method").capitalize)
    request = request_class.new(uri)
    operation.fetch("requestHeaders", []).each do |header|
      request[header.fetch("name")] = header.fetch("value")
    end
    request.body = bytes

    response = with_http(uri) { |http| http.request(request) }
    return if response.code.to_i.between?(200, 299)

    raise AppStoreConnectError, "Screenshot byte upload failed with HTTP #{response.code}."
  end

  private

  def request(method, path, body: nil, allow: [])
    uri = path.start_with?("http") ? URI(path) : URI("#{BASE_URL}#{path}")
    attempts = 0

    begin
      loop do
        attempts += 1
        request_class = Net::HTTP.const_get(method.to_s.capitalize)
        http_request = request_class.new(uri)
        http_request["Authorization"] = "Bearer #{jwt}"
        http_request["Content-Type"] = "application/json" if body
        http_request.body = JSON.generate(body) if body

        response = with_http(uri) { |http| http.request(http_request) }
        status = response.code.to_i
        parsed = response.body.to_s.empty? ? nil : JSON.parse(response.body)
        return parsed if status.between?(200, 299) || allow.include?(status)

        if (status == 429 || status >= 500) && attempts < 4
          sleep(attempts * 2)
          next
        end

        details = Array(parsed && parsed["errors"]).map do |error|
          [error["code"], error["title"], error["detail"]].compact.join(": ")
        end.join(" | ")
        raise AppStoreConnectError, "#{method.to_s.upcase} #{uri.request_uri} failed (HTTP #{status}): #{details}"
      end
    rescue JSON::ParserError => error
      raise AppStoreConnectError, "Apple returned invalid JSON for #{uri.request_uri}: #{error.message}"
    end
  end

  def with_http(uri)
    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 20,
      read_timeout: 90
    ) { |http| yield http }
  end

  def jwt
    now = Time.now.to_i
    header = { alg: "ES256", kid: @key_id, typ: "JWT" }
    payload = { iss: @issuer_id, iat: now, exp: now + 900, aud: "appstoreconnect-v1" }
    signing_input = [header, payload].map { |part| urlsafe(JSON.generate(part)) }.join(".")
    der_signature = @private_key.dsa_sign_asn1(OpenSSL::Digest::SHA256.digest(signing_input))
    sequence = OpenSSL::ASN1.decode(der_signature)
    raw_signature = sequence.value.map do |integer|
      [integer.value.to_s(16).rjust(64, "0")].pack("H*")
    end.join
    "#{signing_input}.#{urlsafe(raw_signature)}"
  end

  def urlsafe(value)
    Base64.urlsafe_encode64(value, padding: false)
  end
end

class ReleaseSync
  EDITABLE_INFO_STATES = %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED].freeze
  REVIEW_FALLBACK = {
    "contactFirstName" => "Dominic",
    "contactLastName" => "Barker",
    "contactEmail" => "dombarker@gmail.com",
    "demoAccountRequired" => false
  }.freeze

  def initialize(client:, payload_directory:)
    @client = client
    @payload_directory = File.expand_path(payload_directory)
    @payload = JSON.parse(File.read(File.join(@payload_directory, "app.json")))
  end

  def run
    validate_local_payload!
    app = find_app!
    puts "Authenticated and matched App Store app #{@payload.fetch("appleId")}."

    version = find_or_create_version(app.fetch("id"))
    update_version(version.fetch("id"))
    app_info = find_editable_app_info!(app.fetch("id"))
    locale = sync_app_info_localization(app_info.fetch("id"))
    sync_categories(app_info.fetch("id"))
    sync_age_rating(app_info.fetch("id"))
    version_localization = sync_version_localization(version.fetch("id"), locale)
    sync_review_details(version.fetch("id"), app.fetch("id"))
    attach_processed_build(version.fetch("id"), app.fetch("id"))
    sync_screenshots(version_localization.fetch("id"))

    puts "App Store Connect preparation is complete. No submission or release action was called."
  end

  private

  def query(path, parameters)
    encoded = URI.encode_www_form(parameters)
    encoded.empty? ? path : "#{path}?#{encoded}"
  end

  def validate_local_payload!
    raise AppStoreConnectError, "Upload payload must target iOS." unless @payload["platform"] == "IOS"

    %w[name subtitle promotional_text description keywords release_notes support_url marketing_url privacy_policy_url].each do |name|
      path = metadata_path(name)
      raise AppStoreConnectError, "Missing metadata file: #{path}" unless File.file?(path)
    end

    expected = @payload.fetch("screenshotOrder")
    @payload.fetch("screenshots").each_value do |relative_directory|
      directory = File.expand_path(relative_directory, @payload_directory)
      expected.each do |filename|
        path = File.join(directory, filename)
        raise AppStoreConnectError, "Missing screenshot: #{path}" unless File.file?(path)
      end
    end
  end

  def find_app!
    response = @client.collection(
      query("/v1/apps", "filter[bundleId]" => @payload.fetch("bundleId"), "limit" => "10")
    )
    app = response.fetch("data").find { |item| item.fetch("id") == @payload.fetch("appleId") }
    raise AppStoreConnectError, "The API key cannot access the expected app and bundle ID." unless app

    app
  end

  def find_or_create_version(app_id)
    versions = versions_for(app_id)
    version = versions.find do |item|
      attributes = item.fetch("attributes", {})
      attributes["platform"] == @payload.fetch("platform") &&
        attributes["versionString"] == @payload.fetch("version")
    end
    return version if version

    puts "Creating App Store version #{@payload.fetch("version")} with manual release."
    @client.post(
      "/v1/appStoreVersions",
      {
        data: {
          type: "appStoreVersions",
          attributes: {
            platform: @payload.fetch("platform"),
            versionString: @payload.fetch("version"),
            copyright: @payload.fetch("copyright"),
            releaseType: "MANUAL"
          },
          relationships: {
            app: { data: { type: "apps", id: app_id } }
          }
        }
      }
    ).fetch("data")
  end

  def update_version(version_id)
    @client.patch(
      "/v1/appStoreVersions/#{version_id}",
      {
        data: {
          type: "appStoreVersions",
          id: version_id,
          attributes: {
            copyright: @payload.fetch("copyright"),
            releaseType: "MANUAL",
            usesIdfa: false
          }
        }
      }
    )
    puts "Version copyright and manual-release mode are set."
  end

  def versions_for(app_id)
    @client.collection(
      query(
        "/v1/apps/#{app_id}/appStoreVersions",
        "filter[platform]" => @payload.fetch("platform"),
        "limit" => "200"
      )
    ).fetch("data")
  end

  def find_editable_app_info!(app_id)
    5.times do |attempt|
      infos = @client.collection(
        query("/v1/apps/#{app_id}/appInfos", "limit" => "50")
      ).fetch("data")
      editable = infos.find { |item| EDITABLE_INFO_STATES.include?(item.dig("attributes", "state")) }
      return editable if editable
      sleep(2) if attempt < 4
    end

    raise AppStoreConnectError, "No editable app-info record appeared after creating/finding the version."
  end

  def sync_app_info_localization(app_info_id)
    localizations = @client.collection(
      query("/v1/appInfos/#{app_info_id}/appInfoLocalizations", "limit" => "200")
    ).fetch("data")
    localization, locale = choose_localization(localizations, @payload.fetch("locale"))
    attributes = {
      name: metadata("name"),
      subtitle: metadata("subtitle"),
      privacyPolicyUrl: metadata("privacy_policy_url")
    }

    if localization
      @client.patch(
        "/v1/appInfoLocalizations/#{localization.fetch("id")}",
        { data: { type: "appInfoLocalizations", id: localization.fetch("id"), attributes: attributes } }
      )
    else
      response = @client.post(
        "/v1/appInfoLocalizations",
        {
          data: {
            type: "appInfoLocalizations",
            attributes: attributes.merge(locale: locale),
            relationships: {
              appInfo: { data: { type: "appInfos", id: app_info_id } }
            }
          }
        }
      )
      localization = response.fetch("data")
    end

    puts "App name, subtitle, and privacy URL are set for #{locale}."
    locale
  end

  def choose_localization(localizations, desired_locale)
    exact = localizations.find { |item| item.dig("attributes", "locale") == desired_locale }
    return [exact, desired_locale] if exact

    language = desired_locale.split("-").first
    matching_language = localizations.select do |item|
      item.dig("attributes", "locale").to_s.split("-").first == language
    end
    if matching_language.length == 1
      existing_locale = matching_language.first.dig("attributes", "locale")
      puts "Using the existing #{existing_locale} localization instead of adding duplicate English metadata."
      return [matching_language.first, existing_locale]
    end

    [nil, desired_locale]
  end

  def sync_categories(app_info_id)
    response = @client.collection(
      query(
        "/v1/appCategories",
        "filter[platforms]" => "IOS",
        "include" => "subcategories",
        "limit" => "50",
        "limit[subcategories]" => "50"
      )
    )
    categories = (response.fetch("data") + response.fetch("included")).each_with_object({}) do |item, memo|
      memo[item.fetch("id")] = item
    end
    required_ids = [
      @payload.fetch("primaryCategory"),
      @payload.fetch("secondaryCategory"),
      *@payload.fetch("secondarySubcategories")
    ]
    missing = required_ids.reject { |id| categories.key?(id) }
    raise AppStoreConnectError, "Apple did not return expected category IDs: #{missing.join(", ")}" unless missing.empty?

    first_subcategory, second_subcategory = @payload.fetch("secondarySubcategories")
    linkage = ->(id) { { data: { type: "appCategories", id: id } } }
    @client.patch(
      "/v1/appInfos/#{app_info_id}",
      {
        data: {
          type: "appInfos",
          id: app_info_id,
          relationships: {
            primaryCategory: linkage.call(@payload.fetch("primaryCategory")),
            secondaryCategory: linkage.call(@payload.fetch("secondaryCategory")),
            secondarySubcategoryOne: linkage.call(first_subcategory),
            secondarySubcategoryTwo: linkage.call(second_subcategory)
          }
        }
      }
    )
    puts "Categories are set to Education, then Games / Family / Puzzle."
  end

  def sync_age_rating(app_info_id)
    declaration = @client.get("/v1/appInfos/#{app_info_id}/ageRatingDeclaration").fetch("data")
    attributes = JSON.parse(File.read(File.join(@payload_directory, "age_rating.json")))
    @client.patch(
      "/v1/ageRatingDeclarations/#{declaration.fetch("id")}",
      {
        data: {
          type: "ageRatingDeclarations",
          id: declaration.fetch("id"),
          attributes: attributes
        }
      }
    )
    puts "The truthful age-rating questionnaire and ages 6–8 Kids band are set."
  end

  def sync_version_localization(version_id, locale)
    localizations = @client.collection(
      query("/v1/appStoreVersions/#{version_id}/appStoreVersionLocalizations", "limit" => "200")
    ).fetch("data")
    localization = localizations.find { |item| item.dig("attributes", "locale") == locale }
    attributes = {
      description: metadata("description"),
      keywords: metadata("keywords"),
      marketingUrl: metadata("marketing_url"),
      promotionalText: metadata("promotional_text"),
      supportUrl: metadata("support_url"),
      whatsNew: metadata("release_notes")
    }

    if localization
      @client.patch(
        "/v1/appStoreVersionLocalizations/#{localization.fetch("id")}",
        {
          data: {
            type: "appStoreVersionLocalizations",
            id: localization.fetch("id"),
            attributes: attributes
          }
        }
      )
    else
      localization = @client.post(
        "/v1/appStoreVersionLocalizations",
        {
          data: {
            type: "appStoreVersionLocalizations",
            attributes: attributes.merge(locale: locale),
            relationships: {
              appStoreVersion: { data: { type: "appStoreVersions", id: version_id } }
            }
          }
        }
      ).fetch("data")
    end

    puts "Description, keywords, URLs, promotional text, and What's New are set for #{locale}."
    localization
  end

  def sync_review_details(version_id, app_id)
    current = @client.get("/v1/appStoreVersions/#{version_id}/appStoreReviewDetail", allow: [404])
    notes = File.read(File.join(@payload_directory, "review_notes.txt")).sub(/\s+\z/, "")

    if current && current["data"]
      detail_id = current.fetch("data").fetch("id")
      @client.patch(
        "/v1/appStoreReviewDetails/#{detail_id}",
        {
          data: {
            type: "appStoreReviewDetails",
            id: detail_id,
            attributes: { notes: notes, demoAccountRequired: false }
          }
        }
      )
    else
      contact = previous_review_contact(app_id).merge(REVIEW_FALLBACK) { |_key, previous, _fallback| previous }
      @client.post(
        "/v1/appStoreReviewDetails",
        {
          data: {
            type: "appStoreReviewDetails",
            attributes: contact.merge("notes" => notes),
            relationships: {
              appStoreVersion: { data: { type: "appStoreVersions", id: version_id } }
            }
          }
        }
      )
    end
    puts "Review notes are set; existing private review contact details were retained where available."
  end

  def previous_review_contact(app_id)
    versions_for(app_id)
      .sort_by { |item| item.dig("attributes", "createdDate").to_s }
      .reverse_each do |version|
        response = @client.get(
          "/v1/appStoreVersions/#{version.fetch("id")}/appStoreReviewDetail",
          allow: [404]
        )
        next unless response && response["data"]

        attributes = response.fetch("data").fetch("attributes", {})
        keys = %w[contactFirstName contactLastName contactPhone contactEmail]
        contact = attributes.select { |key, value| keys.include?(key) && !value.to_s.empty? }
        return contact unless contact.empty?
      end
    {}
  end

  def sync_screenshots(localization_id)
    sets = @client.collection(
      query("/v1/appStoreVersionLocalizations/#{localization_id}/appScreenshotSets", "limit" => "50")
    ).fetch("data")

    managed_display_types = @payload.fetch("screenshots").keys
    inherited_sets = sets.reject do |item|
      managed_display_types.include?(item.dig("attributes", "screenshotDisplayType"))
    end
    unless inherited_sets.empty?
      inherited_types = inherited_sets.map { |item| item.dig("attributes", "screenshotDisplayType") }
      if ENV["ASC_REMOVE_INHERITED_SCREENSHOT_SETS"] == "1"
        inherited_sets.each do |item|
          display_type = item.dig("attributes", "screenshotDisplayType")
          puts "Removing inherited #{display_type} set from the editable version draft only."
          @client.delete("/v1/appScreenshotSets/#{item.fetch("id")}")
        end
        sets -= inherited_sets
      else
        raise AppStoreConnectError,
              "The editable version contains inherited screenshot sets: #{inherited_types.inspect}. " \
              "Refusing to leave stale device-specific media in the draft."
      end
    end

    @payload.fetch("screenshots").each do |display_type, relative_directory|
      screenshot_set = sets.find { |item| item.dig("attributes", "screenshotDisplayType") == display_type }
      screenshot_set ||= create_screenshot_set(localization_id, display_type)
      directory = File.expand_path(relative_directory, @payload_directory)
      sync_screenshot_set(screenshot_set.fetch("id"), directory)
    end
  end

  def create_screenshot_set(localization_id, display_type)
    @client.post(
      "/v1/appScreenshotSets",
      {
        data: {
          type: "appScreenshotSets",
          attributes: { screenshotDisplayType: display_type },
          relationships: {
            appStoreVersionLocalization: {
              data: { type: "appStoreVersionLocalizations", id: localization_id }
            }
          }
        }
      }
    ).fetch("data")
  end

  def sync_screenshot_set(set_id, directory)
    expected_names = @payload.fetch("screenshotOrder")
    existing = @client.collection(
      query("/v1/appScreenshotSets/#{set_id}/appScreenshots", "limit" => "50")
    ).fetch("data")
    existing_names = existing.map { |item| item.dig("attributes", "fileName") }
    unless existing_names == expected_names.first(existing_names.length)
      if ENV["ASC_REPLACE_DRAFT_SCREENSHOTS"] == "1"
        puts "Replacing #{existing.length} inherited screenshot(s) in the editable version draft only."
        existing.each { |item| @client.delete("/v1/appScreenshots/#{item.fetch("id")}") }
        existing_names = []
      else
        raise AppStoreConnectError,
              "The draft screenshot set contains an unexpected order; refusing to delete or overwrite it. " \
              "Existing: #{existing_names.inspect}; expected prefix: " \
              "#{expected_names.first(existing_names.length).inspect}."
      end
    end

    expected_names.drop(existing_names.length).each do |filename|
      upload_screenshot(set_id, File.join(directory, filename))
    end
    puts "Screenshot set #{File.basename(directory)} has #{expected_names.length} ordered images."
  end

  def upload_screenshot(set_id, path)
    reservation = @client.post(
      "/v1/appScreenshots",
      {
        data: {
          type: "appScreenshots",
          attributes: { fileName: File.basename(path), fileSize: File.size(path) },
          relationships: {
            appScreenshotSet: { data: { type: "appScreenshotSets", id: set_id } }
          }
        }
      }
    ).fetch("data")

    bytes = File.binread(path)
    reservation.dig("attributes", "uploadOperations").each do |operation|
      offset = operation.fetch("offset")
      length = operation.fetch("length")
      @client.upload(operation, bytes.byteslice(offset, length))
    end

    screenshot_id = reservation.fetch("id")
    @client.patch(
      "/v1/appScreenshots/#{screenshot_id}",
      {
        data: {
          type: "appScreenshots",
          id: screenshot_id,
          attributes: {
            uploaded: true,
            sourceFileChecksum: Digest::MD5.file(path).hexdigest
          }
        }
      }
    )
    wait_for_screenshot(screenshot_id, File.basename(path))
  end

  def wait_for_screenshot(screenshot_id, filename)
    60.times do
      screenshot = @client.get("/v1/appScreenshots/#{screenshot_id}").fetch("data")
      state = screenshot.dig("attributes", "assetDeliveryState", "state")
      return if state == "COMPLETE"
      raise AppStoreConnectError, "Apple rejected screenshot #{filename}." if %w[FAILED ERROR].include?(state)
      sleep(2)
    end
    raise AppStoreConnectError, "Timed out while Apple processed screenshot #{filename}."
  end

  def attach_processed_build(version_id, app_id)
    builds = @client.collection(
      query(
        "/v1/builds",
        "filter[app]" => app_id,
        "filter[version]" => @payload.fetch("build"),
        "filter[preReleaseVersion.version]" => @payload.fetch("version"),
        "filter[preReleaseVersion.platform]" => @payload.fetch("platform"),
        "sort" => "-uploadedDate",
        "limit" => "10"
      )
    ).fetch("data")
    build = builds.find { |item| item.dig("attributes", "processingState") == "VALID" }
    unless build
      puts "Build #{@payload.fetch("build")} is not processed yet; attach it after Apple marks it VALID."
      return
    end

    @client.patch(
      "/v1/appStoreVersions/#{version_id}/relationships/build",
      { data: { type: "builds", id: build.fetch("id") } }
    )
    puts "Processed build #{@payload.fetch("build")} is attached to version #{@payload.fetch("version")}."
  end

  def metadata(name)
    File.read(metadata_path(name)).sub(/\s+\z/, "")
  end

  def metadata_path(name)
    File.join(@payload_directory, @payload.fetch("locale"), "#{name}.txt")
  end
end

if $PROGRAM_NAME == __FILE__
  key_id = ENV.fetch("ASC_KEY_ID", "7RQS4HKVN3")
  issuer_id = ENV["ASC_ISSUER_ID"].to_s.strip
  abort "Set ASC_ISSUER_ID to the team Issuer ID from App Store Connect → Users and Access → Integrations." if issuer_id.empty?

  key_path = ENV.fetch("ASC_KEY_PATH", File.expand_path("~/Downloads/AuthKey_#{key_id}.p8"))
  abort "App Store Connect key not found at #{key_path}." unless File.file?(key_path)

  begin
    client = AppStoreConnectClient.new(key_id: key_id, issuer_id: issuer_id, key_path: key_path)
    payload_directory = File.expand_path("UploadPayload", __dir__)
    ReleaseSync.new(client: client, payload_directory: payload_directory).run
  rescue AppStoreConnectError, KeyError, OpenSSL::PKey::PKeyError => error
    warn "Release sync stopped safely: #{error.message}"
    exit 1
  end
end
