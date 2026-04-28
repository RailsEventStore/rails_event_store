# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp/tools/stream_events"

module RubyEventStore
  module MCP
    module Tools
      ::RSpec.describe StreamEvents do
        let(:event_store) { RubyEventStore::Client.new }
        let(:tool) { StreamEvents.new }

        class OrderCreated < RubyEventStore::Event; end
        class OrderShipped < RubyEventStore::Event; end

        describe "#name" do
          it { expect(tool.name).to eq("stream_events") }
        end

        describe "#schema" do
          it "has expected structure" do
            expect(tool.schema).to eq(
              name: "stream_events",
              description: "List events in a stream with optional filters",
              inputSchema: {
                type: "object",
                properties: {
                  stream_name: { type: "string", description: "Stream name" },
                  limit: { type: "integer", description: "Max number of events (default: 20)" },
                  type: { type: "string", description: "Filter by event type class name" },
                  after: { type: "string", description: "Filter events newer than timestamp (ISO8601)" },
                  before: { type: "string", description: "Filter events older than timestamp (ISO8601)" },
                  from: { type: "string", description: "Start reading from event ID (exclusive)" }
                },
                required: ["stream_name"]
              }
            )
          end
        end

        describe "#call" do
          it "returns no events message for empty stream" do
            expect(tool.call(event_store, "stream_name" => "empty")).to eq("(no events)")
          end

          it "formats events with iso8601 timestamp, type and id in brackets" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, "stream_name" => "Order$1")
            expect(result).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z  \S.*OrderCreated.*\[.{36}\]/)
          end

          it "filters by event type" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$1")
            result = tool.call(event_store, "stream_name" => "Order$1", "type" => "RubyEventStore::MCP::Tools::OrderCreated")
            expect(result).to include("OrderCreated")
            expect(result).not_to include("OrderShipped")
          end

          it "limits number of events" do
            3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "Order$1") }
            result = tool.call(event_store, "stream_name" => "Order$1", "limit" => 2)
            expect(result.lines.count).to eq(2)
          end

          it "filters by after timestamp" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            future = (Time.now + 3600).iso8601
            event_store.publish(OrderShipped.new, stream_name: "Order$1")
            result = tool.call(event_store, "stream_name" => "Order$1", "after" => future)
            expect(result).to include("(no events)")
          end

          it "filters by before timestamp" do
            past = (Time.now - 3600).iso8601
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, "stream_name" => "Order$1", "before" => past)
            expect(result).to include("(no events)")
          end

          it "reads from a given event id" do
            first = OrderCreated.new
            second = OrderShipped.new
            event_store.publish(first, stream_name: "Order$1")
            event_store.publish(second, stream_name: "Order$1")
            result = tool.call(event_store, "stream_name" => "Order$1", "from" => first.event_id)
            expect(result).to include("OrderShipped")
            expect(result).not_to include("OrderCreated")
          end

          it "raises for unknown event type" do
            expect { tool.call(event_store, "stream_name" => "Order$1", "type" => "NonExistentType") }
              .to raise_error(/Unknown event type/)
          end

          it "only returns events from the specified stream" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Other$1")
            result = tool.call(event_store, "stream_name" => "Order$1")
            expect(result).to include("OrderCreated")
            expect(result).not_to include("OrderShipped")
          end

          it "defaults to limit 20" do
            21.times { event_store.publish(RubyEventStore::Event.new, stream_name: "Order$1") }
            result = tool.call(event_store, "stream_name" => "Order$1")
            expect(result.lines.count).to eq(20)
          end
        end
      end
    end
  end
end
