require "spec_helper"

module RubyEventStore
  RSpec.describe Browser do
    include Browser::IntegrationHelpers

    let(:event_store) do
      RubyEventStore::Client.new(
        repository: RubyEventStore::InMemoryRepository.new,
        correlation_id_generator: -> { "3f68a86f-7510-461b-afdf-b0d08cdf3d70" }
      )
    end

    specify "requsting stream resource" do
      api_client.get "/api/streams/all"

      expect(api_client.last_response).to be_ok
      expect(api_client.parsed_body["data"]).to eq(
        {
          "id" => "all",
          "type" => "streams",
          "attributes" => {
            "related_streams" => nil
          },
          "relationships" => {
            "events" => {
              "links" => {
                "self" => "http://www.example.com/api/streams/all/relationships/events"
              }
            }
          }
        }
      )
    end

    specify do
      event_store.publish(dummy_event, stream_name: "dummy")
      api_client.get "/api/streams/all/relationships/events"

      expect(api_client.last_response).to be_ok
      expect(api_client.parsed_body["data"]).to match_array([event_resource])

      api_client.get "/api/streams/dummy/relationships/events"

      expect(api_client.last_response).to be_ok
      expect(api_client.parsed_body["data"]).to match_array([event_resource])
    end

    specify do
      event_store.publish(dummy_event, stream_name: "dummy")
      api_client.get "/api/events/#{dummy_event.event_id}"

      expect(api_client.last_response).to be_ok
      expect(api_client.parsed_body["data"]).to match(event_resource_with_streams)
    end

    specify "requesting non-existing event" do
      api_client.get "/api/events/73947fbd-90d7-4e1c-be2a-d7ff1900c409"

      api_client.last_response
      expect(api_client.last_response).to be_not_found
      expect(api_client.last_response.body).to be_empty
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
            valid_at: "2020-01-01T12:00:00.000001Z",
            correlation_id: "3f68a86f-7510-461b-afdf-b0d08cdf3d70"
          },
          correlation_stream_name: "$by_correlation_id_3f68a86f-7510-461b-afdf-b0d08cdf3d70",
          causation_stream_name: "$by_causation_id_a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
          parent_event_id: nil,
          type_stream_name: "$by_type_DummyEvent"
        }
      )
    end

    specify "with event without correlation_id" do
      event =
        TimeEnrichment.with(
          DummyEvent.new(event_id: "a562dc5c-97c0-4fe9-8b81-10f9bd0e825f"),
          timestamp: Time.utc(2020, 1, 1, 12, 0, 0, 1)
        )
      json = Browser::JsonApiEvent.new(event, nil).to_h

      expect(json).to match(
        id: "a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
        type: "events",
        attributes: {
          event_type: "DummyEvent",
          data: {
          },
          metadata: {
            timestamp: "2020-01-01T12:00:00.000001Z",
            valid_at: "2020-01-01T12:00:00.000001Z"
          },
          correlation_stream_name: nil,
          causation_stream_name: "$by_causation_id_a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
          parent_event_id: nil,
          type_stream_name: "$by_type_DummyEvent"
        }
      )
    end

    specify "with fancy stream name" do
      api_client.get "/api/streams/foo%2Fbar.xml"

      expect(api_client.last_response).to be_ok
      expect(api_client.parsed_body["data"]).to eq(
        {
          "id" => "foo/bar.xml",
          "type" => "streams",
          "attributes" => {
            "related_streams" => nil
          },
          "relationships" => {
            "events" => {
              "links" => {
                "self" => "http://www.example.com/api/streams/foo%2Fbar.xml/relationships/events"
              }
            }
          }
        }
      )
    end

    def dummy_event(id = SecureRandom.uuid)
      @dummy_event ||=
        TimeEnrichment.with(
          DummyEvent.new(
            event_id: id,
            data: {
              foo: 1,
              bar: 2.0,
              baz: "3"
            },
            metadata: {
              correlation_id: "3f68a86f-7510-461b-afdf-b0d08cdf3d70"
            }
          ),
          timestamp: Time.utc(2020, 1, 1, 12, 0, 0, 1)
        )
    end

    def event_resource_with_streams
      event_resource.merge("relationships" => { "streams" => { "data" => [{ "id" => "dummy", "type" => "streams" }] } })
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
            "valid_at" => "2020-01-01T12:00:00.000001Z",
            "correlation_id" => "3f68a86f-7510-461b-afdf-b0d08cdf3d70"
          },
          "correlation_stream_name" => "$by_correlation_id_3f68a86f-7510-461b-afdf-b0d08cdf3d70",
          "causation_stream_name" => "$by_causation_id_#{dummy_event.event_id}",
          "parent_event_id" => nil,
          "type_stream_name" => "$by_type_DummyEvent"
        }
      }
    end
  end
end
