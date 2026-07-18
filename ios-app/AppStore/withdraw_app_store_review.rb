#!/usr/bin/env ruby
# frozen_string_literal: true

# Cancels one explicitly named iOS App Review submission, detaches its verified build,
# and renames that editable App Store version to the replacement version in app.json.
# Every mutation is preceded and followed by read-only guards. The script never deletes
# an App Store version and is safe to rerun while cancellation or replacement is underway.

require "json"
require "rubygems/version"
require "uri"
require_relative "sync_app_store_connect"

class ReviewWithdrawal
  WITHDRAWABLE_STATES = %w[WAITING_FOR_REVIEW IN_REVIEW].freeze
  ACTIVE_STATES = %w[
    READY_FOR_REVIEW
    WAITING_FOR_REVIEW
    IN_REVIEW
    UNRESOLVED_ISSUES
    CANCELING
    COMPLETING
  ].freeze
  CANCELLATION_STATES = %w[CANCELING WAITING_FOR_REVIEW IN_REVIEW].freeze
  EDITABLE_VERSION_STATES = %w[DEVELOPER_REJECTED PREPARE_FOR_SUBMISSION].freeze

  def initialize(client:, payload_directory:, expected_version:, expected_build:)
    @client = client
    @payload = JSON.parse(File.read(File.join(payload_directory, "app.json")))
    @expected_version = expected_version
    @expected_build = expected_build
  end

  def run
    validate_version_order!
    app = find_app
    app_id = app.fetch("id")
    versions = versions_for(app_id)
    old_version = unique_version(versions, @expected_version)
    replacement_version = unique_version(versions, replacement_version_string)
    replacement_build = find_valid_build!(
      app_id: app_id,
      version: replacement_version_string,
      build: replacement_build_string,
      label: "replacement"
    )

    if old_version.nil?
      verify_completed_replacement!(app_id, replacement_version, replacement_build)
      puts "REPLACEMENT ALREADY COMPLETE: version #{replacement_version_string} is ready for metadata sync."
      return
    end
    if replacement_version
      raise AppStoreConnectError,
            "Both submitted version #{@expected_version} and replacement version " \
            "#{replacement_version_string} exist; refusing to choose between them."
    end

    old_build = find_valid_build!(
      app_id: app_id,
      version: @expected_version,
      build: @expected_build,
      label: "submitted"
    )
    submission = submission_for_replacement(app_id, old_version.fetch("id"))
    submission_state = submission.dig("attributes", "state")
    submitted_version = sole_submitted_version!(submission.fetch("id"))
    verify_old_release!(
      version: submitted_version,
      expected_id: old_version.fetch("id"),
      submission_state: submission_state,
      old_build: old_build
    )

    case submission_state
    when *WITHDRAWABLE_STATES
      puts "Verified the sole iOS review item is version #{@expected_version} " \
           "build #{@expected_build} in #{submission_state}."
      cancel_submission(submission.fetch("id"))
    when "CANCELING"
      puts "Cancellation is already in progress for version #{@expected_version}; resuming verification."
    when "COMPLETE"
      puts "The expected submission is already canceled; resuming replacement verification."
    else
      raise AppStoreConnectError,
            "Review submission cannot be replaced from state #{submission_state.inspect}."
    end

    wait_for_submission_cancellation(submission.fetch("id")) unless submission_state == "COMPLETE"
    wait_for_version_state(old_version.fetch("id"), "DEVELOPER_REJECTED")
    detach_old_build(old_version.fetch("id"), old_build.fetch("id"))
    rename_version(old_version.fetch("id"))
    verify_renamed_version!(app_id, old_version.fetch("id"), replacement_build)

    puts "REPLACEMENT READY: version #{@expected_version} was canceled, detached, and renamed " \
         "to #{replacement_version_string}. Run the metadata sync next."
  end

  private

  def replacement_version_string
    @payload.fetch("version")
  end

  def replacement_build_string
    @payload.fetch("build")
  end

  def query(path, parameters)
    "#{path}?#{URI.encode_www_form(parameters)}"
  end

  def validate_version_order!
    unless @payload.fetch("platform") == "IOS"
      raise AppStoreConnectError, "The replacement payload must target iOS."
    end

    old_version = Gem::Version.new(@expected_version)
    replacement_version = Gem::Version.new(replacement_version_string)
    return if replacement_version > old_version

    raise AppStoreConnectError,
          "Replacement version #{replacement_version_string.inspect} must be newer than " \
          "submitted version #{@expected_version.inspect}."
  rescue ArgumentError
    raise AppStoreConnectError, "Submitted and replacement versions must be valid dotted version numbers."
  end

  def find_app
    apps = @client.collection(
      query("/v1/apps", "filter[bundleId]" => @payload.fetch("bundleId"), "limit" => "10")
    ).fetch("data")
    app = apps.find { |item| item.fetch("id") == @payload.fetch("appleId") }
    raise AppStoreConnectError, "Expected app record was not found." unless app

    app
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

  def unique_version(versions, version_string)
    matches = versions.select do |version|
      version.dig("attributes", "platform") == @payload.fetch("platform") &&
        version.dig("attributes", "versionString") == version_string
    end
    raise AppStoreConnectError, "More than one iOS version #{version_string} exists." if matches.length > 1

    matches.first
  end

  def find_valid_build!(app_id:, version:, build:, label:)
    builds = @client.collection(
      query(
        "/v1/builds",
        "filter[app]" => app_id,
        "filter[version]" => build,
        "filter[preReleaseVersion.version]" => version,
        "filter[preReleaseVersion.platform]" => @payload.fetch("platform"),
        "sort" => "-uploadedDate",
        "limit" => "10"
      )
    ).fetch("data")
    valid = builds.select { |item| item.dig("attributes", "processingState") == "VALID" }
    unless valid.length == 1
      raise AppStoreConnectError,
            "Expected exactly one VALID #{label} build #{version} (#{build}), found #{valid.length}."
    end

    attributes = valid.first.fetch("attributes", {})
    unless attributes["version"] == build
      raise AppStoreConnectError, "#{label.capitalize} build number changed during lookup."
    end
    unless attributes["usesNonExemptEncryption"] == false
      raise AppStoreConnectError,
            "#{label.capitalize} build #{version} (#{build}) has unresolved export compliance."
    end

    valid.first
  end

  def submissions_for(app_id)
    @client.collection(
      query(
        "/v1/apps/#{app_id}/reviewSubmissions",
        "filter[platform]" => @payload.fetch("platform"),
        "limit" => "200"
      )
    ).fetch("data")
  end

  def submission_for_replacement(app_id, old_version_id)
    submissions = submissions_for(app_id)
    active = submissions.select { |item| ACTIVE_STATES.include?(item.dig("attributes", "state")) }
    if active.length > 1
      raise AppStoreConnectError, "More than one active iOS review submission exists."
    end
    if active.length == 1
      version = sole_submitted_version!(active.first.fetch("id"))
      unless version.fetch("id") == old_version_id
        raise AppStoreConnectError, "The active review submission targets a different App Store version."
      end
      return active.first
    end

    completed = submissions.select { |item| item.dig("attributes", "state") == "COMPLETE" }
                           .sort_by { |item| item.dig("attributes", "submittedDate").to_s }
                           .reverse
    recovered = completed.find do |submission|
      submitted_version_if_sole(submission.fetch("id"))&.fetch("id") == old_version_id
    end
    raise AppStoreConnectError, "No active or canceled submission targets the expected version." unless recovered

    recovered
  end

  def submission_items(submission_id)
    @client.collection(
      query(
        "/v1/reviewSubmissions/#{submission_id}/items",
        "include" => "appStoreVersion",
        "limit" => "50"
      )
    )
  end

  def sole_submitted_version!(submission_id)
    response = submission_items(submission_id)
    item_count = response.fetch("data").length
    unless item_count == 1
      raise AppStoreConnectError,
            "Expected exactly one review submission item, found #{item_count}."
    end

    versions = response.fetch("included", []).select do |item|
      item.fetch("type") == "appStoreVersions"
    end
    unless versions.length == 1
      raise AppStoreConnectError,
            "The sole review item is not exactly one App Store version."
    end

    versions.first
  end

  def submitted_version_if_sole(submission_id)
    response = submission_items(submission_id)
    return nil unless response.fetch("data").length == 1

    versions = response.fetch("included", []).select do |item|
      item.fetch("type") == "appStoreVersions"
    end
    versions.length == 1 ? versions.first : nil
  end

  def verify_old_release!(version:, expected_id:, submission_state:, old_build:)
    attributes = version.fetch("attributes", {})
    unless version.fetch("id") == expected_id && attributes["versionString"] == @expected_version
      raise AppStoreConnectError, "The submitted App Store version does not match the withdrawal guard."
    end
    unless attributes["platform"] == @payload.fetch("platform")
      raise AppStoreConnectError, "The submitted App Store version is not iOS."
    end

    allowed_version_states = if submission_state == "COMPLETE"
                               %w[WAITING_FOR_REVIEW IN_REVIEW DEVELOPER_REJECTED]
                             elsif submission_state == "CANCELING"
                               %w[WAITING_FOR_REVIEW IN_REVIEW DEVELOPER_REJECTED]
                             else
                               [submission_state]
                             end
    unless allowed_version_states.include?(attributes["appVersionState"])
      raise AppStoreConnectError,
            "Version state #{attributes["appVersionState"].inspect} does not match " \
            "submission state #{submission_state.inspect}."
    end

    attached = attached_build_data(version.fetch("id"))
    if WITHDRAWABLE_STATES.include?(submission_state) || submission_state == "CANCELING"
      unless attached && attached.fetch("id") == old_build.fetch("id")
        raise AppStoreConnectError,
              "Submitted version is not attached to guarded build #{@expected_build}."
      end
    elsif attached && attached.fetch("id") != old_build.fetch("id")
      raise AppStoreConnectError, "Canceled version is attached to an unexpected build."
    end
  end

  def attached_build_data(version_id)
    @client.get("/v1/appStoreVersions/#{version_id}/relationships/build").fetch("data")
  end

  def cancel_submission(submission_id)
    @client.patch(
      "/v1/reviewSubmissions/#{submission_id}",
      {
        data: {
          type: "reviewSubmissions",
          id: submission_id,
          attributes: { canceled: true }
        }
      }
    )
  end

  def wait_for_submission_cancellation(submission_id)
    90.times do
      submission = @client.get("/v1/reviewSubmissions/#{submission_id}").fetch("data")
      state = submission.dig("attributes", "state")
      return if state == "COMPLETE"
      unless CANCELLATION_STATES.include?(state)
        raise AppStoreConnectError, "Withdrawal moved to unexpected state #{state.inspect}."
      end
      sleep(2)
    end
    raise AppStoreConnectError, "Timed out while Apple canceled the review submission."
  end

  def wait_for_version_state(version_id, expected_state)
    60.times do
      version = @client.get("/v1/appStoreVersions/#{version_id}").fetch("data")
      return version if version.dig("attributes", "appVersionState") == expected_state
      sleep(2)
    end
    raise AppStoreConnectError,
          "Timed out waiting for version #{@expected_version} to become #{expected_state}."
  end

  def detach_old_build(version_id, expected_build_id)
    attached = attached_build_data(version_id)
    if attached.nil?
      puts "Submitted build is already detached."
      return
    end
    unless attached.fetch("id") == expected_build_id
      raise AppStoreConnectError, "Refusing to detach an unexpected build."
    end

    @client.patch(
      "/v1/appStoreVersions/#{version_id}/relationships/build",
      { data: nil }
    )
    30.times do
      return if attached_build_data(version_id).nil?
      sleep(2)
    end
    raise AppStoreConnectError, "Timed out while detaching submitted build #{@expected_build}."
  end

  def rename_version(version_id)
    @client.patch(
      "/v1/appStoreVersions/#{version_id}",
      {
        data: {
          type: "appStoreVersions",
          id: version_id,
          attributes: {
            versionString: replacement_version_string,
            copyright: @payload.fetch("copyright"),
            releaseType: "MANUAL",
            usesIdfa: false
          }
        }
      }
    )
  end

  def verify_renamed_version!(app_id, version_id, replacement_build)
    version = @client.get("/v1/appStoreVersions/#{version_id}").fetch("data")
    attributes = version.fetch("attributes", {})
    expected = {
      "platform" => @payload.fetch("platform"),
      "versionString" => replacement_version_string,
      "copyright" => @payload.fetch("copyright"),
      "releaseType" => "MANUAL",
      "usesIdfa" => false
    }
    expected.each do |key, value|
      next if attributes[key] == value

      raise AppStoreConnectError,
            "Renamed version #{key} mismatch: expected #{value.inspect}, received #{attributes[key].inspect}."
    end
    unless EDITABLE_VERSION_STATES.include?(attributes["appVersionState"])
      raise AppStoreConnectError,
            "Renamed version is in unsupported state #{attributes["appVersionState"].inspect}."
    end
    raise AppStoreConnectError, "Renamed version unexpectedly has a build attached." if attached_build_data(version_id)

    versions = versions_for(app_id)
    if unique_version(versions, @expected_version)
      raise AppStoreConnectError, "Submitted version #{@expected_version} still exists after renaming."
    end
    replacement = unique_version(versions, replacement_version_string)
    unless replacement && replacement.fetch("id") == version_id
      raise AppStoreConnectError, "Replacement version did not retain the guarded App Store version ID."
    end

    # The build is deliberately left detached for sync_app_store_connect.rb to attach after
    # it finishes replacing metadata and screenshots.
    unless replacement_build.dig("attributes", "processingState") == "VALID"
      raise AppStoreConnectError, "Replacement build stopped being VALID during replacement."
    end
  end

  def verify_completed_replacement!(app_id, replacement_version, replacement_build)
    unless replacement_version
      raise AppStoreConnectError,
            "Neither submitted version #{@expected_version} nor replacement version " \
            "#{replacement_version_string} exists."
    end

    version_id = replacement_version.fetch("id")
    matching_history = submissions_for(app_id).select do |submission|
      submission.dig("attributes", "state") == "COMPLETE" &&
        submitted_version_if_sole(submission.fetch("id"))&.fetch("id") == version_id
    end
    if matching_history.empty?
      raise AppStoreConnectError,
            "Replacement version exists without a canceled single-item submission history."
    end

    attributes = replacement_version.fetch("attributes", {})
    expected = {
      "platform" => @payload.fetch("platform"),
      "versionString" => replacement_version_string,
      "copyright" => @payload.fetch("copyright"),
      "releaseType" => "MANUAL",
      "usesIdfa" => false
    }
    expected.each do |key, value|
      next if attributes[key] == value

      raise AppStoreConnectError,
            "Existing replacement #{key} mismatch: expected #{value.inspect}, " \
            "received #{attributes[key].inspect}."
    end
    unless EDITABLE_VERSION_STATES.include?(attributes["appVersionState"])
      raise AppStoreConnectError,
            "Existing replacement version is in unsupported state " \
            "#{attributes["appVersionState"].inspect}."
    end

    attached = attached_build_data(version_id)
    if attached && attached.fetch("id") != replacement_build.fetch("id")
      raise AppStoreConnectError, "Existing replacement version is attached to an unexpected build."
    end
  end
end

key_id = ENV.fetch("ASC_KEY_ID", "7RQS4HKVN3")
issuer_id = ENV["ASC_ISSUER_ID"].to_s.strip
abort "Set ASC_ISSUER_ID before withdrawing from review." if issuer_id.empty?

expected_version = ENV["ASC_WITHDRAW_VERSION"].to_s.strip
abort "Set ASC_WITHDRAW_VERSION to the exact submitted version you intend to withdraw." if expected_version.empty?

expected_build = ENV["ASC_WITHDRAW_BUILD"].to_s.strip
abort "Set ASC_WITHDRAW_BUILD to the exact submitted build you intend to withdraw." if expected_build.empty?

key_path = ENV.fetch("ASC_KEY_PATH", File.expand_path("~/Downloads/AuthKey_#{key_id}.p8"))
abort "App Store Connect key not found at #{key_path}." unless File.file?(key_path)

begin
  client = AppStoreConnectClient.new(key_id: key_id, issuer_id: issuer_id, key_path: key_path)
  ReviewWithdrawal.new(
    client: client,
    payload_directory: File.expand_path("UploadPayload", __dir__),
    expected_version: expected_version,
    expected_build: expected_build
  ).run
rescue AppStoreConnectError, KeyError, ArgumentError, OpenSSL::PKey::PKeyError => error
  warn "App Store review replacement failed: #{error.message}"
  exit 1
end
