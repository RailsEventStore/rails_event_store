require "spec_helper"

module RubyEventStore
  RSpec.describe Browser do
    specify "requsting stream resource with related streams" do
      app =
        RubyEventStore::Browser::App.for(
          event_store_locator: -> { event_store },
          related_streams_query: ->(stream_name) { stream_name == "dummy" ? ["even-dummier"] : [] }
        )
      test_client = ApiClient.new(app, "www.example.com")

      test_client.get "/api/streams/all"
      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["related_streams"]).to eq([])

      test_client.get "/api/streams/dummy"
      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["related_streams"]).to eq(["even-dummier"])
    end

    specify "default related streams query returns nil" do
      app = RubyEventStore::Browser::App.for(event_store_locator: -> { event_store })
      test_client = ApiClient.new(app, "www.example.com")

      test_client.get "/api/streams/all"
      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["related_streams"]).to eq(nil)
    end

    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
  end
end
