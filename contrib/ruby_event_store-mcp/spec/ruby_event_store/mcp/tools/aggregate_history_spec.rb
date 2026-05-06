# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp/tools/aggregate_history"

module RubyEventStore
  module MCP
    module Tools
      ::RSpec.describe AggregateHistory do
        let(:event_store) { RubyEventStore::Client.new }
        let(:tool) { AggregateHistory.new }

        class OrderCreated < RubyEventStore::Event; end
        class OrderShipped < RubyEventStore::Event; end

        describe "#name" do
          it { expect(tool.name).to eq("aggregate_history") }
        end

        describe "#schema" do
          it "has expected structure" do
            expect(tool.schema).to eq(
              name: "aggregate_history",
              description: "Show the full event history of an aggregate instance",
              inputSchema: {
                type: "object",
                properties: {
                  aggregate_type: { type: "string", description: "Aggregate class name (e.g. Order, Payment::Invoice)" },
                  aggregate_id: { type: "string", description: "Aggregate ID (UUID or other identifier)" }
                },
                required: %w[aggregate_type aggregate_id]
              }
            )
          end
        end

        describe "#call" do
          it "shows stream name formed from aggregate type and id" do
            event_store.publish(OrderCreated.new, stream_name: "Order$abc-123")
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "abc-123")
            expect(result).to include("Aggregate: Order$abc-123")
          end

          it "shows event count" do
            3.times { event_store.publish(OrderCreated.new, stream_name: "Order$1") }
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "1")
            expect(result).to include("Events:    3")
          end

          it "shows zero events for unknown aggregate" do
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "missing")
            expect(result).to include("Events:    0")
          end

          it "omits event list for empty stream" do
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "missing")
            expect(result.lines.count).to eq(2)
          end

          it "does not add trailing newline for empty stream" do
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "missing")
            expect(result).not_to end_with("\n")
          end

          it "separates header and event list with a blank line" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "1")
            expect(result.lines[2].chomp).to eq("")
          end

          it "puts each event on its own line" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$1")
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "1")
            expect(result.lines.count).to eq(5)
          end

          it "formats event type as plain class name without object notation" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "1")
            expect(result).not_to include("#<")
          end

          it "lists events in chronological order" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$1")
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "1")
            created_pos = result.index("OrderCreated")
            shipped_pos = result.index("OrderShipped")
            expect(created_pos).to be < shipped_pos
          end

          it "includes event type for each event" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "1")
            expect(result).to include("OrderCreated")
          end

          it "includes event id for each event" do
            e = OrderCreated.new
            event_store.publish(e, stream_name: "Order$1")
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "1")
            expect(result).to include("[#{e.event_id}]")
          end

          it "includes iso8601 timestamp for each event" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "1")
            expect(result).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z/)
          end

          it "only shows events from the aggregate stream" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$2")
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "1")
            expect(result).to include("Events:    1")
            expect(result).not_to include("OrderShipped")
          end

          it "places aggregate header on first line" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "1")
            expect(result.lines.first.chomp).to eq("Aggregate: Order$1")
          end

          it "places event count on second line" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, "aggregate_type" => "Order", "aggregate_id" => "1")
            expect(result.lines[1].chomp).to eq("Events:    1")
          end
        end
      end
    end
  end
end
