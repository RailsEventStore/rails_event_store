require "spec_helper"

module RubyEventStore
  RSpec.describe Browser do
    specify "requesting event with correlation stream" do
      event = DummyEvent.new(
        event_id: "a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
        data: {},
        metadata: {
          correlation_id: "a7243789-999f-4ef2-8511-b1c686b83fad"
        }
      )
      event_store.publish(event, stream_name: "dummy")
      test_client.get "/api/events/#{event.event_id}"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["correlation_stream_name"]).to eq(
        "$by_correlation_id_a7243789-999f-4ef2-8511-b1c686b83fad",
      )
    end

    specify "requesting event with causation stream" do
      event = DummyEvent.new(
        event_id: "a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
        data: {},
      )
      event_store.publish(event, stream_name: "dummy")
      test_client.get "/api/events/#{event.event_id}"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["causation_stream_name"]).to eq(
        "$by_causation_id_a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
      )
    end

    specify "requesting event with parent event id" do
      parent_event = DummyEvent.new(
        event_id: "44427ded-e8a7-4ee4-bf31-09f34433d506",
        data: {},
      )
      event_store.publish(parent_event, stream_name: "dummy")
      caused_event = DummyEvent.new(
        event_id: "a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
        data: {},
        metadata: {
          causation_id: parent_event.event_id,
        }
      )
      event_store.publish(caused_event, stream_name: "dummy")
      test_client.get "/api/events/#{caused_event.event_id}"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["parent_event_id"]).to eq(
        "44427ded-e8a7-4ee4-bf31-09f34433d506",
      )
    end

    specify "requesting event which is caused by something other than event" do
      caused_event = DummyEvent.new(
        event_id: "a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
        data: {},
        metadata: {
          causation_id: "44427ded-e8a7-4ee4-bf31-09f34433d506",
        }
      )
      event_store.publish(caused_event, stream_name: "dummy")
      test_client.get "/api/events/#{caused_event.event_id}"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["parent_event_id"]).to be_nil
    end

    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
    let(:test_client) { TestClientWithJsonApiLinter.new(app_builder(event_store)) }

    def app_builder(event_store)
      RubyEventStore::Browser::App.for(
        event_store_locator: -> { event_store },
        host: 'http://www.example.com'
      )
    end
  end
end
