# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    include Browser::IntegrationHelpers

    let(:correlation_id) { SecureRandom.uuid }
    let(:dummy_event) do
      DummyEvent.new(
        data: {
          foo: 1,
          bar: 2.0,
          baz: "3",
          bax: 1.0 / 0,
          bay: {
            baq: [-1.0 / 0, 0.0 / 0]
          }
        }
      )
    end
    let(:parent_event) { DummyEvent.new }
    let(:timestamp) { Time.utc(2020, 1, 1, 12, 0, 0, 1) }
    let(:stream_name) { "dummy" }

    specify "happy path" do
      event_store.append(parent_event)
      event_store.with_metadata(
        correlation_id: correlation_id,
        timestamp: timestamp,
        causation_id: parent_event.event_id
      ) { event_store.publish(dummy_event, stream_name: stream_name) }

      api_client.get "/api/events/#{dummy_event.event_id}"

      expect(api_client.last_response).to be_ok
      expect(api_client.parsed_body["data"]).to match(
        {
          "id" => dummy_event.event_id,
          "type" => "events",
          "attributes" => {
            "event_type" => dummy_event.event_type,
            "data" => {
              "foo" => dummy_event.data[:foo],
              "bar" => dummy_event.data[:bar],
              "baz" => dummy_event.data[:baz],
              "bax" => "Infinity",
              "bay" => {
                "baq" => %w[-Infinity NaN]
              }
            },
            "metadata" => {
              "timestamp" => timestamp.iso8601(6),
              "valid_at" => timestamp.iso8601(6),
              "correlation_id" => correlation_id,
              "causation_id" => parent_event.event_id
            },
            "correlation_stream_name" =>
              "$by_correlation_id_#{dummy_event.correlation_id}",
            "causation_stream_name" =>
              "$by_causation_id_#{dummy_event.event_id}",
            "type_stream_name" => "$by_type_#{dummy_event.event_type}",
            "parent_event_id" => parent_event.event_id
          },
          "relationships" => {
            "streams" => {
              "data" => [
                { "id" => stream_name, "type" => "streams" },
                {
                  "id" => "$by_correlation_id_#{dummy_event.correlation_id}",
                  "type" => "streams"
                },
                {
                  "id" => "$by_causation_id_#{parent_event.event_id}",
                  "type" => "streams"
                },
                {
                  "id" => "$by_type_#{dummy_event.event_type}",
                  "type" => "streams"
                }
              ]
            }
          }
        }
      )
    end

    specify "not existing" do
      api_client.get "/api/events/#{dummy_event.event_id}"

      expect(api_client.last_response).to be_not_found
      expect(api_client.last_response.body).to be_empty
    end
  end
end
