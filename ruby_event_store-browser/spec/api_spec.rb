require "spec_helper"

module TimeEnrichment
  def with(event, timestamp: Time.now.utc, valid_at: nil)
    event.metadata[:timestamp] ||= timestamp
    event.metadata[:valid_at] ||= valid_at || timestamp
    event
  end
  module_function :with
end

module RubyEventStore
  RSpec.describe Browser do
    specify "requsting stream resource" do
      test_client.get "/streams/all"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]).to eq({
        "id" => "all",
        "type" => "streams",
        "attributes" => {
          "related_streams" => nil,
        },
        "relationships" => {
          "events" => {
            "links" => {
              "self" => "http://www.example.com/streams/all/relationships/events",
            }
          }
        }
      })
    end

    specify do
      event_store.publish(dummy_event, stream_name: "dummy")
      test_client.get "/streams/all/relationships/events"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]).to match_array([event_resource])

      test_client.get "/streams/dummy/relationships/events"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]).to match_array([event_resource])
    end

    specify do
      event_store.publish(dummy_event, stream_name: "dummy")
      test_client.get "/events/#{dummy_event.event_id}"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]).to match(event_resource)
    end

    specify "requesting non-existing event" do
      test_client.get "/events/73947fbd-90d7-4e1c-be2a-d7ff1900c409"

      test_client.last_response
      expect(test_client.last_response).to be_not_found
      expect(test_client.last_response.body).to be_empty
    end

    specify do
      json = Browser::JsonApiEvent.new(dummy_event("a562dc5c-97c0-4fe9-8b81-10f9bd0e825f"), nil).to_h

      expect(json).to match(
        id: "a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
        type: "events",
        attributes: {
          event_type: "DummyEvent",
          data: {
            foo: 1,
            bar: 2.0,
            baz: "3"
          },
          metadata: {
            timestamp: "2020-01-01T12:00:00.000001Z",
            valid_at:  "2020-01-01T12:00:00.000001Z"
          },
          correlation_stream_name: nil,
          causation_stream_name: "$by_causation_id_a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
          parent_event_id: nil,
          type_stream_name: "$by_type_DummyEvent",
        },
      )
    end

    def dummy_event(id = SecureRandom.uuid)
      @dummy_event ||= TimeEnrichment.with(
        DummyEvent.new(
          event_id: id,
          data: {
            foo: 1,
            bar: 2.0,
            baz: "3"
          }
        ),
        timestamp: Time.utc(2020, 1, 1, 12, 0, 0, 1)
      )
    end

    def event_resource
      {
        "id" => dummy_event.event_id,
        "type" => "events",
        "attributes" => {
          "event_type" => "DummyEvent",
          "data" => {
            "foo" => 1,
            "bar" => 2.0,
            "baz" => "3"
          },
          "metadata" => {
            "timestamp" => "2020-01-01T12:00:00.000001Z",
            "valid_at"  => "2020-01-01T12:00:00.000001Z"
          },
          "correlation_stream_name" => nil,
          "causation_stream_name" => "$by_causation_id_#{dummy_event.event_id}",
          "parent_event_id" => nil,
          "type_stream_name" => "$by_type_DummyEvent",
        },
      }
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
