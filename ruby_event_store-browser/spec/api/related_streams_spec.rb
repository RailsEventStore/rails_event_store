require "spec_helper"

module RubyEventStore
  RSpec.describe Browser do
    include Browser::IntegrationHelpers

    specify "requsting stream resource with related streams" do
      app =
        RubyEventStore::Browser::App.for(
          event_store_locator: -> { event_store },
          related_streams_query: ->(stream_name) do
            stream_name == "dummy" ? ["even-dummier"] : []
          end
        )
      api_client = ApiClient.new(app, "www.example.com")

      api_client.get "/api/streams/all"
      expect(api_client.last_response).to be_ok
      expect(
        api_client.parsed_body["data"]["attributes"]["related_streams"]
      ).to eq([])

      api_client.get "/api/streams/dummy"
      expect(api_client.last_response).to be_ok
      expect(
        api_client.parsed_body["data"]["attributes"]["related_streams"]
      ).to eq(["even-dummier"])
    end

    specify "default related streams query returns nil" do
      app =
        RubyEventStore::Browser::App.for(
          event_store_locator: -> { event_store }
        )
      api_client = ApiClient.new(app, "www.example.com")

      api_client.get "/api/streams/all"
      expect(api_client.last_response).to be_ok
      expect(
        api_client.parsed_body["data"]["attributes"]["related_streams"]
      ).to eq(nil)
    end

    let(:event_store) do
      RubyEventStore::Client.new(
        repository: RubyEventStore::InMemoryRepository.new
      )
    end
  end
end
