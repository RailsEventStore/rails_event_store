# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp/tools/stream_show"

module RubyEventStore
  module MCP
    module Tools
      ::RSpec.describe StreamShow do
        let(:event_store) { RubyEventStore::Client.new }
        let(:tool) { StreamShow.new }

        class OrderCreated < RubyEventStore::Event; end
        class OrderShipped < RubyEventStore::Event; end

        describe "#name" do
          it { expect(tool.name).to eq("stream_show") }
        end

        describe "#schema" do
          it "has expected structure" do
            expect(tool.schema).to eq(
              name: "stream_show",
              description: "Show event count, version, and first/last event for a stream",
              inputSchema: {
                type: "object",
                properties: {
                  stream_name: { type: "string", description: "Stream name" }
                },
                required: ["stream_name"]
              }
            )
          end
        end

        describe "#call" do
          it "shows stream name and event count" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "Order$1")
            result = tool.call(event_store, "stream_name" => "Order$1")
            expect(result).to include("Stream:  Order$1")
            expect(result).to include("Events:  1")
          end

          it "shows version as count minus one" do
            3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "Order$1") }
            result = tool.call(event_store, "stream_name" => "Order$1")
            expect(result).to include("Version: 2")
          end

          it "shows first and last event types with iso8601 timestamps" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$1")
            result = tool.call(event_store, "stream_name" => "Order$1")
            expect(result).to match(/First:   \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z.*OrderCreated/)
            expect(result).to match(/Last:    \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z.*OrderShipped/)
          end

          it "shows first event type as class name" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, "stream_name" => "Order$1")
            expect(result).to match(/First:   .* \(RubyEventStore::/)
          end

          it "shows last event type as class name" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, "stream_name" => "Order$1")
            expect(result).to match(/Last:    .* \(RubyEventStore::/)
          end

          it "places each field on its own line" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, "stream_name" => "Order$1")
            expect(result.lines.first.chomp).to eq("Stream:  Order$1")
            expect(result.lines[1].chomp).to eq("Events:  1")
          end

          it "only counts events from the specified stream" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Other$1")
            result = tool.call(event_store, "stream_name" => "Order$1")
            expect(result).to include("Events:  1")
          end

          it "omits version and timestamps for empty stream" do
            result = tool.call(event_store, "stream_name" => "empty-stream")
            expect(result).to include("Events:  0")
            expect(result).not_to include("Version")
          end
        end
      end
    end
  end
end
