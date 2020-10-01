require 'spec_helper'

module RubyEventStore
  RSpec.describe Browser do
    it "should handle metadata timestamp" do
      dummy_event = DummyEvent.new
      event_store.publish(dummy_event, stream_name: "dummy")
      response = test_client.get "/api/streams/all/relationships/events"
      expect(response).to be_ok

      metadata = JSON.parse(response.body)["data"][0]["attributes"]["metadata"]
      expect(metadata["timestamp"]).to eq(dummy_event.metadata[:timestamp].iso8601(TIMESTAMP_PRECISION))
      expect(metadata["valid_at"]).to eq(dummy_event.metadata[:valid_at].iso8601(TIMESTAMP_PRECISION))
    end

    let(:test_client) { TestClient.new(app_builder(event_store)) }
    let(:event_store) do
      RubyEventStore::Client.new(
        repository: RubyEventStore::InMemoryRepository.new(serializer: JSON),
      )
    end

    def app_builder(event_store)
      RubyEventStore::Browser::App.for(
        event_store_locator: -> { event_store },
        host: 'http://www.example.com'
      )
    end
  end
end
