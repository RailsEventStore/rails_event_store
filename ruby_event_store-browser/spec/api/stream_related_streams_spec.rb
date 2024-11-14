# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    include Browser::IntegrationHelpers

    specify "default related streams query returns nil" do
      api_client.get "/api/streams/all"

      expect(api_client.last_response).to be_ok
      expect(
        api_client.parsed_body["data"]["attributes"]["related_streams"]
      ).to eq(nil)
    end

    specify "requsting stream resource with related streams" do
      api_client = ApiClient.new(app_with_related_streams)

      api_client.get "/api/streams/all"
      expect(api_client.last_response).to be_ok
      expect(
        api_client.parsed_body["data"]["attributes"]["related_streams"]
      ).to eq([])

      api_client.get "/api/streams/dummy"
      expect(api_client.last_response).to be_ok
      expect(
        api_client.parsed_body["data"]["attributes"]["related_streams"]
      ).to eq(["dummy_too"])
    end

    let(:app_with_related_streams) do
      Browser::App.for(
        event_store_locator: -> { event_store },
        related_streams_query: ->(stream_name) do
          stream_name == "dummy" ? ["dummy_too"] : []
        end
      )
    end
  end
end
