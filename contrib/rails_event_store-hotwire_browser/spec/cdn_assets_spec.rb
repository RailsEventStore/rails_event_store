# frozen_string_literal: true

require "spec_helper"

module RailsEventStore
  ::RSpec.describe HotwireBrowser do
    include HotwireBrowser::IntegrationHelpers

    specify "links assets locally by default" do
      body = web_client.get("/").body

      expect(body).to include(%(href="/rails_event_store_hotwire_browser.css"))
      expect(body).to include(%(src="/browser.js"))
    end

    specify "links assets from the CDN when installed from git" do
      allow(HotwireBrowser::GemSource).to receive(:new).and_return(
        instance_double(HotwireBrowser::GemSource, from_git?: true, version: "0123456789ab"),
      )

      body = web_client.get("/").body

      expect(body).to include(%(href="https://cdn.railseventstore.org/0123456789ab/rails_event_store_hotwire_browser.css"))
      expect(body).to include(%(src="https://cdn.railseventstore.org/0123456789ab/browser.js"))
    end
  end
end
