# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp/tools/search"

module RubyEventStore
  module MCP
    module Tools
      ::RSpec.describe Search do
        let(:event_store) { RubyEventStore::Client.new }
        let(:tool) { Search.new }

        class OrderCreated < RubyEventStore::Event; end
        class OrderShipped < RubyEventStore::Event; end

        describe "#name" do
          it { expect(tool.name).to eq("search") }
        end

        describe "#schema" do
          it "has expected structure" do
            expect(tool.schema).to eq(
              name: "search",
              description: "Search events across all streams by type, time range, or stream name",
              inputSchema: {
                type: "object",
                properties: {
                  type: { type: "string", description: "Filter by event type class name" },
                  after: { type: "string", description: "Filter events newer than timestamp (ISO8601)" },
                  before: { type: "string", description: "Filter events older than timestamp (ISO8601)" },
                  stream: { type: "string", description: "Limit search to a specific stream" },
                  limit: { type: "integer", description: "Max number of events (default: 50)" }
                }
              }
            )
          end
        end

        describe "#call" do
          it "returns no events message when nothing matches" do
            expect(tool.call(event_store, {})).to eq("(no events found)")
          end

          it "lists all events when no filters given" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$1")
            result = tool.call(event_store, {})
            expect(result).to include("OrderCreated")
            expect(result).to include("OrderShipped")
          end

          it "formats events with iso8601 timestamp and id in brackets" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, {})
            expect(result).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z  \S.*OrderCreated.*\[.{36}\]/)
          end

          it "includes full event type name with double-space separator" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, {})
            expect(result).to include("  RubyEventStore::MCP::Tools::OrderCreated  [")
          end

          it "filters by event type" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$1")
            result = tool.call(event_store, "type" => "RubyEventStore::MCP::Tools::OrderCreated")
            expect(result).to include("OrderCreated")
            expect(result).not_to include("OrderShipped")
          end

          it "limits to a specific stream" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$2")
            result = tool.call(event_store, "stream" => "Order$1")
            expect(result).to include("OrderCreated")
            expect(result).not_to include("OrderShipped")
          end

          it "respects limit" do
            3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "Order$1") }
            result = tool.call(event_store, "limit" => 2)
            expect(result.lines.count).to eq(2)
          end

          it "filters by after timestamp" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            future = (Time.now + 3600).iso8601
            result = tool.call(event_store, "after" => future)
            expect(result).to eq("(no events found)")
          end

          it "filters by before timestamp" do
            past = (Time.now - 3600).iso8601
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, "before" => past)
            expect(result).to eq("(no events found)")
          end

          it "defaults to limit 50" do
            51.times { event_store.publish(RubyEventStore::Event.new, stream_name: "Order$1") }
            result = tool.call(event_store, {})
            expect(result.lines.count).to eq(50)
          end
        end
      end
    end
  end
end
