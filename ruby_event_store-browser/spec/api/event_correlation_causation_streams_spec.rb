# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    include Browser::IntegrationHelpers

    specify "requesting event with correlation stream" do
      event_store.append(
        event =
          DummyEvent.new(
            metadata: {
              correlation_id: "a7243789-999f-4ef2-8511-b1c686b83fad"
            }
          )
      )

      api_client.get "/api/events/#{event.event_id}"

      expect(api_client.last_response).to be_ok
      expect(
        api_client.parsed_body["data"]["attributes"]["correlation_stream_name"]
      ).to eq("$by_correlation_id_a7243789-999f-4ef2-8511-b1c686b83fad")
    end

    specify "requesting event with causation stream" do
      event_store.append(event = DummyEvent.new)

      api_client.get "/api/events/#{event.event_id}"

      expect(api_client.last_response).to be_ok
      expect(
        api_client.parsed_body["data"]["attributes"]["causation_stream_name"]
      ).to eq("$by_causation_id_#{event.event_id}")
    end

    specify "requesting event with parent event id" do
      event_store.append(parent_event = DummyEvent.new)
      event_store.append(
        caused_event =
          DummyEvent.new(metadata: { causation_id: parent_event.event_id })
      )

      api_client.get "/api/events/#{caused_event.event_id}"

      expect(api_client.last_response).to be_ok
      expect(
        api_client.parsed_body["data"]["attributes"]["parent_event_id"]
      ).to eq(parent_event.event_id)
    end

    specify "requesting event which is caused by something other than event" do
      event_store.append(
        caused_event =
          DummyEvent.new(
            metadata: {
              causation_id: "44427ded-e8a7-4ee4-bf31-09f34433d506"
            }
          )
      )

      api_client.get "/api/events/#{caused_event.event_id}"

      expect(api_client.last_response).to be_ok
      expect(
        api_client.parsed_body["data"]["attributes"]["parent_event_id"]
      ).to be_nil
    end
  end
end
