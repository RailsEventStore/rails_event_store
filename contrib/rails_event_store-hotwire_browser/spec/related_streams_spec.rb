# frozen_string_literal: true

require "spec_helper"

module RailsEventStore
  ::RSpec.describe HotwireBrowser do
    include HotwireBrowser::IntegrationHelpers

    specify "no related streams section without a configured query" do
      expect(web_client.get("/streams/all").body).not_to include("Related streams:")
    end

    specify "renders the configured related streams" do
      TestApplication.config.x.rails_event_store_hotwire_browser_related_streams_query =
        ->(stream_name) { stream_name == "dummy" ? ["dummy_too"] : [] }

      body = web_client.get("/streams/dummy").body
      expect(body).to include("Related streams:")
      expect(body).to include(%(href="/streams/dummy_too"))
    ensure
      TestApplication.config.x.rails_event_store_hotwire_browser_related_streams_query = nil
    end
  end
end
