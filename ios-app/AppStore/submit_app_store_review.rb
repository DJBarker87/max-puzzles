#!/usr/bin/env ruby
# frozen_string_literal: true

# Adds the prepared App Store version to a review submission and submits it.
# Unlike sync_app_store_connect.rb, this script intentionally changes the
# production review state. It is repeat-safe for the version in app.json.

require "json"
require "uri"
require_relative "sync_app_store_connect"

class ReviewSubmission
  ACTIVE_STATES = %w[
    READY_FOR_REVIEW
    WAITING_FOR_REVIEW
    IN_REVIEW
    UNRESOLVED_ISSUES
    CANCELING
    COMPLETING
  ].freeze

  SUBMITTED_STATES = %w[WAITING_FOR_REVIEW IN_REVIEW].freeze

  def initialize(client:, payload_directory:)
    @client = client
    @payload_directory = File.expand_path(payload_directory)
    @payload = JSON.parse(File.read(File.join(@payload_directory, "app.json")))
  end

  def run
    app = find_app
    version = find_version(app.fetch("id"))
    verify_version(version)

    submission = active_submission(app.fetch("id"))
    if submission
      verify_submission_targets_version(submission, version.fetch("id"))
    else
      submission = create_submission(app.fetch("id"))
    end

    state = submission.dig("attributes", "state")
    if SUBMITTED_STATES.include?(state)
      puts "Version #{@payload.fetch("version")} is already #{state.downcase.tr("_", " ")}."
      return
    end
    unless state == "READY_FOR_REVIEW"
      raise AppStoreConnectError, "Review submission is in unsupported state #{state.inspect}."
    end

    add_version_if_needed(submission.fetch("id"), version.fetch("id"))
    wait_until_ready(submission.fetch("id"))
    submit(submission.fetch("id"))
    verify_submitted(submission.fetch("id"))
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

  def verify_version(version)
    state = version.dig("attributes", "appVersionState")
    unless %w[PREPARE_FOR_SUBMISSION READY_FOR_REVIEW WAITING_FOR_REVIEW IN_REVIEW].include?(state)
      raise AppStoreConnectError, "Version is in unsupported state #{state.inspect}."
    end

    build = @client.get("/v1/appStoreVersions/#{version.fetch("id")}/build").fetch("data")
    attributes = build.fetch("attributes")
    unless attributes["version"] == @payload.fetch("build")
      raise AppStoreConnectError,
            "Attached build mismatch: expected #{@payload.fetch("build")}, received #{attributes["version"].inspect}."
    end
    unless attributes["processingState"] == "VALID"
      raise AppStoreConnectError, "Attached build is not VALID."
    end
    unless attributes["usesNonExemptEncryption"] == false
      raise AppStoreConnectError, "Attached build has an unresolved export-compliance declaration."
    end

    puts "Version #{@payload.fetch("version")} build #{@payload.fetch("build")} is valid and attached."
  end

  def active_submission(app_id)
    submissions = @client.collection(
      query(
        "/v1/apps/#{app_id}/reviewSubmissions",
        "filter[platform]" => @payload.fetch("platform"),
        "limit" => "200"
      )
    ).fetch("data")
    active = submissions.select { |item| ACTIVE_STATES.include?(item.dig("attributes", "state")) }
    return nil if active.empty?
    raise AppStoreConnectError, "More than one active iOS review submission exists." if active.length > 1

    active.first
  end

  def create_submission(app_id)
    submission = @client.post(
      "/v1/reviewSubmissions",
      {
        data: {
          type: "reviewSubmissions",
          attributes: { platform: @payload.fetch("platform") },
          relationships: {
            app: { data: { type: "apps", id: app_id } }
          }
        }
      }
    ).fetch("data")
    puts "Created the iOS review submission."
    submission
  end

  def submission_version_ids(submission_id)
    response = @client.collection(
      query(
        "/v1/reviewSubmissions/#{submission_id}/items",
        "include" => "appStoreVersion",
        "limit" => "50"
      )
    )
    response.fetch("included", [])
      .select { |item| item.fetch("type") == "appStoreVersions" }
      .map { |item| item.fetch("id") }
      .uniq
  end

  def verify_submission_targets_version(submission, version_id)
    version_ids = submission_version_ids(submission.fetch("id"))
    return if version_ids.empty? || version_ids == [version_id]

    raise AppStoreConnectError, "An active review submission targets a different App Store version."
  end

  def add_version_if_needed(submission_id, version_id)
    if submission_version_ids(submission_id).include?(version_id)
      puts "Version #{@payload.fetch("version")} is already in the draft review submission."
      return
    end

    @client.post(
      "/v1/reviewSubmissionItems",
      {
        data: {
          type: "reviewSubmissionItems",
          relationships: {
            appStoreVersion: {
              data: { type: "appStoreVersions", id: version_id }
            },
            reviewSubmission: {
              data: { type: "reviewSubmissions", id: submission_id }
            }
          }
        }
      }
    )
    puts "Added version #{@payload.fetch("version")} to the review submission."
  end

  def wait_until_ready(submission_id)
    30.times do
      submission = @client.get("/v1/reviewSubmissions/#{submission_id}").fetch("data")
      state = submission.dig("attributes", "state")
      return if state == "READY_FOR_REVIEW"
      raise AppStoreConnectError, "Review submission changed to #{state} before submission." unless state.nil?

      sleep(2)
    end
    raise AppStoreConnectError, "Timed out waiting for the review submission to become ready."
  end

  def submit(submission_id)
    @client.patch(
      "/v1/reviewSubmissions/#{submission_id}",
      {
        data: {
          type: "reviewSubmissions",
          id: submission_id,
          attributes: { submitted: true }
        }
      }
    )
    puts "Submitted version #{@payload.fetch("version")} to App Review."
  end

  def verify_submitted(submission_id)
    30.times do
      submission = @client.get("/v1/reviewSubmissions/#{submission_id}").fetch("data")
      state = submission.dig("attributes", "state")
      if SUBMITTED_STATES.include?(state)
        puts "APP REVIEW STATUS: #{state}"
        return
      end
      raise AppStoreConnectError, "Submission moved to unexpected state #{state}." if state == "UNRESOLVED_ISSUES"

      sleep(2)
    end
    raise AppStoreConnectError, "Timed out while Apple accepted the review submission."
  end
end

key_id = ENV.fetch("ASC_KEY_ID", "7RQS4HKVN3")
issuer_id = ENV["ASC_ISSUER_ID"].to_s.strip
abort "Set ASC_ISSUER_ID before submitting for review." if issuer_id.empty?

key_path = ENV.fetch("ASC_KEY_PATH", File.expand_path("~/Downloads/AuthKey_#{key_id}.p8"))
abort "App Store Connect key not found at #{key_path}." unless File.file?(key_path)

begin
  client = AppStoreConnectClient.new(key_id: key_id, issuer_id: issuer_id, key_path: key_path)
  ReviewSubmission.new(
    client: client,
    payload_directory: File.expand_path("UploadPayload", __dir__)
  ).run
rescue AppStoreConnectError, KeyError, OpenSSL::PKey::PKeyError => error
  warn "App Store review submission failed: #{error.message}"
  exit 1
end
