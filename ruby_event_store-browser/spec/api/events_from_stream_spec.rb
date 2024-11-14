# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    include Browser::IntegrationHelpers

    let(:correlation_id) { SecureRandom.uuid }
    let(:dummy_event) { DummyEvent.new(data: { foo: 1, bar: 2.0, baz: "3" }) }
    let(:timestamp) { Time.utc(2020, 1, 1, 12, 0, 0, 1) }
    let(:stream_name) { "dummy" }

    def publish_dummy_event
      event_store.with_metadata(
        correlation_id: correlation_id,
        timestamp: timestamp
      ) { event_store.append(dummy_event, stream_name: stream_name) }
    end

    specify "happy path" do
      publish_dummy_event

      %w[
        /api/streams/all/relationships/events
        /api/streams/dummy/relationships/events
      ].each do |endpoint|
        api_client.get endpoint
        expect(api_client.last_response).to be_ok
        expect(api_client.parsed_body["data"]).to match_array(
          [
            {
              "id" => dummy_event.event_id,
              "type" => "events",
              "attributes" => {
                "event_type" => dummy_event.event_type,
                "data" => {
                  "foo" => dummy_event.data[:foo],
                  "bar" => dummy_event.data[:bar],
                  "baz" => dummy_event.data[:baz]
                },
                "metadata" => {
                  "timestamp" => timestamp.iso8601(6),
                  "valid_at" => timestamp.iso8601(6),
                  "correlation_id" => correlation_id
                },
                "correlation_stream_name" =>
                  "$by_correlation_id_#{dummy_event.correlation_id}",
                "causation_stream_name" =>
                  "$by_causation_id_#{dummy_event.event_id}",
                "type_stream_name" => "$by_type_#{dummy_event.event_type}",
                "parent_event_id" => nil
              }
            }
          ]
        )
      end
    end
  end
end
