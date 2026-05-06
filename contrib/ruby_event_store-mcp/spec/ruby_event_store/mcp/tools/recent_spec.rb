# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp/tools/recent"

module RubyEventStore
  module MCP
    module Tools
      ::RSpec.describe Recent do
        let(:event_store) { RubyEventStore::Client.new }
        let(:tool) { Recent.new }

        class OrderPlaced < RubyEventStore::Event; end
        class OrderShipped < RubyEventStore::Event; end

        describe "#name" do
          it { expect(tool.name).to eq("recent") }
        end

        describe "#schema" do
          it "has expected structure" do
            expect(tool.schema).to eq(
              name: "recent",
              description: "Show the most recent events across all streams",
              inputSchema: {
                type: "object",
                properties: {
                  limit: { type: "integer", description: "Number of events to return (default: 20)" }
                },
                required: []
              }
            )
          end
        end

        describe "#call" do
          it "returns no events message for empty store" do
            result = tool.call(event_store, {})
            expect(result).to eq("(no events)")
          end

          it "returns events when present" do
            event_store.publish(OrderPlaced.new, stream_name: "Order$1")
            result = tool.call(event_store, {})
            expect(result).not_to eq("(no events)")
          end

          it "returns events most recent first" do
            event_store.publish(OrderPlaced.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$1")
            result = tool.call(event_store, {})
            expect(result.index("OrderShipped")).to be < result.index("OrderPlaced")
          end

          it "respects the limit parameter" do
            5.times { event_store.publish(OrderPlaced.new, stream_name: "Order$1") }
            result = tool.call(event_store, "limit" => 3)
            expect(result.lines.count).to eq(3)
          end

          it "accepts string limit by converting via to_i" do
            5.times { event_store.publish(OrderPlaced.new, stream_name: "Order$1") }
            result = tool.call(event_store, "limit" => "3")
            expect(result.lines.count).to eq(3)
          end

          it "extracts leading digits from partial numeric string limit via to_i" do
            5.times { event_store.publish(OrderPlaced.new, stream_name: "Order$1") }
            result = tool.call(event_store, "limit" => "3abc")
            expect(result.lines.count).to eq(3)
          end

          it "defaults to 20 events when no limit given" do
            25.times { event_store.publish(OrderPlaced.new, stream_name: "Order$1") }
            result = tool.call(event_store, {})
            expect(result.lines.count).to eq(20)
          end

          it "includes event type" do
            event_store.publish(OrderPlaced.new, stream_name: "Order$1")
            result = tool.call(event_store, {})
            expect(result).to include("OrderPlaced")
          end

          it "includes event id" do
            e = OrderPlaced.new
            event_store.publish(e, stream_name: "Order$1")
            result = tool.call(event_store, {})
            expect(result).to include("[#{e.event_id}]")
          end

          it "includes iso8601 timestamp" do
            event_store.publish(OrderPlaced.new, stream_name: "Order$1")
            result = tool.call(event_store, {})
            expect(result).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z/)
          end

          it "includes events from different streams" do
            event_store.publish(OrderPlaced.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$2")
            result = tool.call(event_store, {})
            expect(result).to include("OrderPlaced")
            expect(result).to include("OrderShipped")
          end

          it "formats event type as plain class name without object notation" do
            event_store.publish(OrderPlaced.new, stream_name: "Order$1")
            result = tool.call(event_store, {})
            expect(result).not_to include("#<")
          end
        end
      end
    end
  end
end
