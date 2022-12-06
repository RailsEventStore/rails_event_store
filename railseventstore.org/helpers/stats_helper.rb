# frozen_string_literal: true

require "octokit"
require "faraday"
require "json"

module StatsHelper
  class Stats
    def initialize
      @octokit_client = Octokit::Client.new
      @octokit_client.auto_paginate = true
    end

    def contributors
      @contributors ||= octokit_client.contributors(repo)
    end

    def stargazers_count
      octokit_client.repo(repo)[:stargazers_count]
    end

    def contributors_count
      contributors.size
    end

    def releases_count
      octokit_client.releases(repo).size
    end

    def total_downloads_count
      response = Faraday.get("https://rubygems.org/api/v1/downloads/rails_event_store-1.0.0.json")
      JSON.parse(response.body)["total_downloads"]
    end

    private

    def octokit_client
      @octokit_client
    end

    def repo
      "RailsEventStore/rails_event_store"
    end
  end

  def stats
    Stats.new
  end

  def contributors
    stats.contributors
  end

  def contributors_count
    stats.contributors_count
  end

  def stargazers_count
    stats.stargazers_count
  end

  def releases_count
    stats.releases_count
  end

  def total_downloads
    stats.total_downloads_count
  end
end
