# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    include Browser::IntegrationHelpers

    specify "returns 422 when feature not enabled" do
      api_client.get "/api/event_types"

      expect(api_client.last_response.status).to eq(422)
    end

    specify "returns list of event types when feature enabled" do
      app =
        Browser::App.for(
          event_store_locator: -> { event_store },
          experimental_event_types_query: ->(es) { Browser::EventTypesQuerying::DefaultQuery.new(es) },
        )

      enabled_api_client = ApiClient.new(app, "www.example.com")
      # Define some test event classes
      test_event_1 = Class.new(RubyEventStore::Event)
      stub_const("OrderPlaced", test_event_1)

      test_event_2 = Class.new(RubyEventStore::Event)
      stub_const("OrderCancelled", test_event_2)

      enabled_api_client.get "/api/event_types"

      expect(enabled_api_client.last_response).to be_ok
      expect(enabled_api_client.parsed_body["data"]).to be_an(Array)

      event_types = enabled_api_client.parsed_body["data"]
      order_placed = event_types.find { |et| et["attributes"]["event_type"] == "OrderPlaced" }
      order_cancelled = event_types.find { |et| et["attributes"]["event_type"] == "OrderCancelled" }

      expect(order_placed).to match(
        {
          "id" => "OrderPlaced",
          "type" => "event_types",
          "attributes" => {
            "event_type" => "OrderPlaced",
            "stream_name" => "$by_type_OrderPlaced",
          },
        },
      )

      expect(order_cancelled).to match(
        {
          "id" => "OrderCancelled",
          "type" => "event_types",
          "attributes" => {
            "event_type" => "OrderCancelled",
            "stream_name" => "$by_type_OrderCancelled",
          },
        },
      )
    end

    specify "uses custom query when provided" do
      custom_query =
        lambda do |event_store|
          query = Object.new
          def query.call
            [
              RubyEventStore::Browser::EventTypesQuerying::EventType.new(
                event_type: "CustomEvent",
                stream_name: "$custom_stream",
              ),
            ]
          end
          query
        end

      app =
        Browser::App.for(
          event_store_locator: -> { event_store },
          experimental_event_types_query: custom_query,
        )

      custom_api_client = ApiClient.new(app, "www.example.com")
      custom_api_client.get "/api/event_types"

      expect(custom_api_client.last_response).to be_ok
      expect(custom_api_client.parsed_body["data"]).to match(
        [
          {
            "id" => "CustomEvent",
            "type" => "event_types",
            "attributes" => {
              "event_type" => "CustomEvent",
              "stream_name" => "$custom_stream",
            },
          },
        ],
      )
    end

    specify "passes event_store to query factory" do
      received_event_store = nil
      custom_query =
        lambda do |es|
          received_event_store = es
          query = Object.new
          def query.call
            [
              RubyEventStore::Browser::EventTypesQuerying::EventType.new(
                event_type: "TestEvent",
                stream_name: "$by_type_TestEvent",
              ),
            ]
          end
          query
        end

      app =
        Browser::App.for(
          event_store_locator: -> { event_store },
          experimental_event_types_query: custom_query,
        )

      custom_api_client = ApiClient.new(app, "www.example.com")
      custom_api_client.get "/api/event_types"

      expect(received_event_store).to eq(event_store)
    end
  end
end
