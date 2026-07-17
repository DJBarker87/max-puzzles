#!/usr/bin/env ruby
# frozen_string_literal: true

# Read-only verification for the prepared App Store Connect version.

require "json"
require "uri"
require_relative "sync_app_store_connect"

class ReleaseAudit
  EDITABLE_INFO_STATES = %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED].freeze

  def initialize(client:, payload_directory:)
    @client = client
    @payload_directory = File.expand_path(payload_directory)
    @payload = JSON.parse(File.read(File.join(@payload_directory, "app.json")))
  end

  def run
    app = find_app
    audit_app_record(app)
    audit_commerce(app.fetch("id"))
    version = find_version(app.fetch("id"))
    assert_equal("platform", version.dig("attributes", "platform"), @payload.fetch("platform"))
    assert_equal("version", version.dig("attributes", "versionString"), @payload.fetch("version"))
    assert_equal("copyright", version.dig("attributes", "copyright"), @payload.fetch("copyright"))
    assert_equal("release type", version.dig("attributes", "releaseType"), "MANUAL")
    assert_equal("IDFA declaration", version.dig("attributes", "usesIdfa"), false)
    assert_equal("version state", version.dig("attributes", "appVersionState"), "PREPARE_FOR_SUBMISSION")
    assert_no_submission(version.fetch("id"))

    app_info = find_editable_app_info(app.fetch("id"))
    audit_app_info(app_info)
    audit_age_rating(app_info.fetch("id"))
    localization = audit_version_localization(version.fetch("id"))
    audit_review_details(version.fetch("id"))
    audit_build(version.fetch("id"))
    audit_screenshots(localization.fetch("id"))

    puts "READ-ONLY AUDIT PASSED: version #{@payload.fetch("version")} build #{@payload.fetch("build")} is complete and remains unsubmitted."
  end

  private

  def query(path, parameters)
    "#{path}?#{URI.encode_www_form(parameters)}"
  end

  def find_app
    apps = @client.collection(
      query("/v1/apps", "filter[bundleId]" => @payload.fetch("bundleId"), "limit" => "10")
    ).fetch("data")
    app = apps.find { |item| item.fetch("id") == @payload.fetch("appleId") }
    raise AppStoreConnectError, "Expected app record was not found." unless app

    puts "App and bundle ID match."
    app
  end

  def find_version(app_id)
    versions = @client.collection(
      query(
        "/v1/apps/#{app_id}/appStoreVersions",
        "filter[platform]" => @payload.fetch("platform"),
        "filter[versionString]" => @payload.fetch("version"),
        "limit" => "10"
      )
    ).fetch("data")
    version = versions.find { |item| item.dig("attributes", "versionString") == @payload.fetch("version") }
    raise AppStoreConnectError, "Version #{@payload.fetch("version")} was not found." unless version

    version
  end

  def audit_app_record(app)
    attributes = app.fetch("attributes")
    assert_equal("bundle ID", attributes["bundleId"], @payload.fetch("bundleId"))
    assert_equal("primary locale", attributes["primaryLocale"], @payload.fetch("locale"))
    assert_equal("Made for Kids enrollment", attributes["isOrEverWasMadeForKids"], true)
    valid_rights = %w[DOES_NOT_USE_THIRD_PARTY_CONTENT USES_THIRD_PARTY_CONTENT]
    unless valid_rights.include?(attributes["contentRightsDeclaration"])
      raise AppStoreConnectError, "The app-level content-rights declaration is incomplete."
    end
    puts "Primary locale, Made for Kids enrollment, and content-rights declaration are present."
  end

  def audit_commerce(app_id)
    availability = @client.get("/v1/apps/#{app_id}/appAvailabilityV2").fetch("data")
    assert_equal(
      "availability in new territories",
      availability.dig("attributes", "availableInNewTerritories"),
      true
    )

    schedule = @client.get("/v1/apps/#{app_id}/appPriceSchedule").fetch("data")
    base_territory = @client.get(
      "/v1/appPriceSchedules/#{schedule.fetch("id")}/baseTerritory"
    ).fetch("data")
    assert_equal("price base territory", base_territory.fetch("id"), "GBR")
    prices = @client.collection(
      query(
        "/v1/appPriceSchedules/#{schedule.fetch("id")}/manualPrices",
        "include" => "appPricePoint,territory",
        "limit" => "200"
      )
    )
    customer_prices = prices.fetch("included", []).each_with_object([]) do |item, values|
      next unless item["type"] == "appPricePoints"

      value = item.dig("attributes", "customerPrice")
      values << value if value
    end
    raise AppStoreConnectError, "The inherited app price is not Free." unless customer_prices.include?("0.0")

    puts "Existing availability is retained and the GBR base price is Free."
  end

  def assert_no_submission(version_id)
    response = @client.get(
      "/v1/appStoreVersions/#{version_id}/appStoreVersionSubmission",
      allow: [404]
    )
    raise AppStoreConnectError, "A review submission unexpectedly exists." if response && response["data"]

    puts "No review submission exists."
  end

  def find_editable_app_info(app_id)
    infos = @client.collection(query("/v1/apps/#{app_id}/appInfos", "limit" => "50")).fetch("data")
    info = infos.find { |item| EDITABLE_INFO_STATES.include?(item.dig("attributes", "state")) }
    raise AppStoreConnectError, "Editable app information was not found." unless info

    info
  end

  def audit_app_info(app_info)
    app_info_id = app_info.fetch("id")
    localizations = @client.collection(
      query("/v1/appInfos/#{app_info_id}/appInfoLocalizations", "limit" => "200")
    ).fetch("data")
    localization = localizations.find { |item| item.dig("attributes", "locale") == @payload.fetch("locale") }
    raise AppStoreConnectError, "#{@payload.fetch("locale")} app-info localization is missing." unless localization

    attributes = localization.fetch("attributes")
    assert_equal("name", attributes["name"], metadata("name"))
    assert_equal("subtitle", attributes["subtitle"], metadata("subtitle"))
    assert_equal("privacy URL", attributes["privacyPolicyUrl"], metadata("privacy_policy_url"))

    expected_categories = {
      "primaryCategory" => @payload.fetch("primaryCategory"),
      "secondaryCategory" => @payload.fetch("secondaryCategory"),
      "secondarySubcategoryOne" => @payload.fetch("secondarySubcategories").fetch(0),
      "secondarySubcategoryTwo" => @payload.fetch("secondarySubcategories").fetch(1)
    }
    expected_categories.each do |relationship, expected_id|
      response = @client.get("/v1/appInfos/#{app_info_id}/relationships/#{relationship}")
      assert_equal(relationship, response.dig("data", "id"), expected_id)
    end
    puts "App information, privacy URL, and categories match."
  end

  def audit_age_rating(app_info_id)
    declaration = @client.get("/v1/appInfos/#{app_info_id}/ageRatingDeclaration").fetch("data")
    actual = declaration.fetch("attributes")
    expected = JSON.parse(File.read(File.join(@payload_directory, "age_rating.json")))
    expected.each { |key, value| assert_equal("age rating #{key}", actual[key], value) }
    puts "Age-rating answers and Kids ages 6–8 match."
  end

  def audit_version_localization(version_id)
    localizations = @client.collection(
      query("/v1/appStoreVersions/#{version_id}/appStoreVersionLocalizations", "limit" => "200")
    ).fetch("data")
    localization = localizations.find { |item| item.dig("attributes", "locale") == @payload.fetch("locale") }
    raise AppStoreConnectError, "#{@payload.fetch("locale")} version localization is missing." unless localization

    expected = {
      "description" => metadata("description"),
      "keywords" => metadata("keywords"),
      "marketingUrl" => metadata("marketing_url"),
      "promotionalText" => metadata("promotional_text"),
      "supportUrl" => metadata("support_url"),
      "whatsNew" => metadata("release_notes")
    }
    actual = localization.fetch("attributes")
    expected.each { |key, value| assert_equal("version localization #{key}", actual[key], value) }
    puts "Description, keywords, URLs, promotional text, and What's New match."
    localization
  end

  def audit_review_details(version_id)
    detail = @client.get("/v1/appStoreVersions/#{version_id}/appStoreReviewDetail").fetch("data")
    attributes = detail.fetch("attributes")
    expected_notes = File.read(File.join(@payload_directory, "review_notes.txt")).sub(/\s+\z/, "")
    assert_equal("review notes", attributes["notes"], expected_notes)
    assert_equal("demo account", attributes["demoAccountRequired"], false)
    %w[contactFirstName contactLastName contactPhone contactEmail].each do |field|
      raise AppStoreConnectError, "Review contact #{field} is blank." if attributes[field].to_s.strip.empty?
    end
    puts "Review contact, notes, and no-demo-account setting match."
  end

  def audit_build(version_id)
    build = @client.get("/v1/appStoreVersions/#{version_id}/build").fetch("data")
    attributes = build.fetch("attributes")
    assert_equal("build number", attributes["version"], @payload.fetch("build"))
    assert_equal("build state", attributes["processingState"], "VALID")
    assert_equal("non-exempt encryption", attributes["usesNonExemptEncryption"], false)
    puts "Build #{@payload.fetch("build")} is valid, attached, and declares no non-exempt encryption."
  end

  def audit_screenshots(localization_id)
    sets = @client.collection(
      query("/v1/appStoreVersionLocalizations/#{localization_id}/appScreenshotSets", "limit" => "50")
    ).fetch("data")
    expected_display_types = @payload.fetch("screenshots").keys
    actual_display_types = sets.map { |item| item.dig("attributes", "screenshotDisplayType") }
    assert_equal("screenshot display types", actual_display_types.sort, expected_display_types.sort)
    expected_names = @payload.fetch("screenshotOrder")
    expected_dimensions = {
      "APP_IPHONE_67" => [1320, 2868],
      "APP_IPAD_PRO_3GEN_129" => [2048, 2732]
    }

    @payload.fetch("screenshots").each do |display_type, relative_directory|
      set = sets.find { |item| item.dig("attributes", "screenshotDisplayType") == display_type }
      raise AppStoreConnectError, "Screenshot set #{display_type} is missing." unless set

      screenshots = @client.collection(
        query("/v1/appScreenshotSets/#{set.fetch("id")}/appScreenshots", "limit" => "50")
      ).fetch("data")
      names = screenshots.map { |item| item.dig("attributes", "fileName") }
      assert_equal("#{display_type} screenshot order", names, expected_names)
      screenshots.each do |screenshot|
        attributes = screenshot.fetch("attributes")
        assert_equal("#{attributes["fileName"]} delivery state", attributes.dig("assetDeliveryState", "state"), "COMPLETE")
        dimensions = [attributes.dig("imageAsset", "width"), attributes.dig("imageAsset", "height")]
        assert_equal("#{attributes["fileName"]} dimensions", dimensions, expected_dimensions.fetch(display_type))
        local_path = File.join(File.expand_path(relative_directory, @payload_directory), attributes.fetch("fileName"))
        assert_equal(
          "#{attributes["fileName"]} checksum",
          attributes["sourceFileChecksum"],
          Digest::MD5.file(local_path).hexdigest
        )
      end
      puts "#{display_type}: eight byte-matched screenshots in the intended order."
    end
  end

  def metadata(name)
    File.read(File.join(@payload_directory, @payload.fetch("locale"), "#{name}.txt")).sub(/\s+\z/, "")
  end

  def assert_equal(label, actual, expected)
    return if actual == expected

    raise AppStoreConnectError, "#{label} mismatch: expected #{expected.inspect}, received #{actual.inspect}."
  end
end

key_id = ENV.fetch("ASC_KEY_ID", "7RQS4HKVN3")
issuer_id = ENV["ASC_ISSUER_ID"].to_s.strip
abort "Set ASC_ISSUER_ID before running the read-only audit." if issuer_id.empty?

key_path = ENV.fetch("ASC_KEY_PATH", File.expand_path("~/Downloads/AuthKey_#{key_id}.p8"))
abort "App Store Connect key not found at #{key_path}." unless File.file?(key_path)

begin
  client = AppStoreConnectClient.new(key_id: key_id, issuer_id: issuer_id, key_path: key_path)
  ReleaseAudit.new(client: client, payload_directory: File.expand_path("UploadPayload", __dir__)).run
rescue AppStoreConnectError, KeyError, OpenSSL::PKey::PKeyError => error
  warn "Read-only App Store Connect audit failed: #{error.message}"
  exit 1
end
