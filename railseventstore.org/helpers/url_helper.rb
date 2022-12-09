# frozen_string_literal: true

module UrlHelper
  def github_url
    "https://github.com/RailsEventStore/rails_event_store"
  end

  def discord_url
    "https://discord.gg/qjPr9ZBpX6"
  end

  def stackoverflow_url
    "https://stackoverflow.com/questions/tagged/rails-event-store"
  end

  def github_discussions_url
    "https://github.com/RailsEventStore/rails_event_store/discussions"
  end

  def twitter_hashtag_url
    "https://twitter.com/hashtag/railseventstore"
  end

  def changelog_url
    "https://github.com/RailsEventStore/rails_event_store/releases/tag/v#{config[:res_version]}"
  end

  def community_path
    "/community"
  end

  def support_path
    "/support"
  end

  def docs_path(version)
    "/docs/#{version}/install"
  end
end
