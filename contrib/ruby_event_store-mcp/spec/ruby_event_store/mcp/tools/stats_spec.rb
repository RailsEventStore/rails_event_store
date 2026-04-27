# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp/tools/stats"

module RubyEventStore
  module MCP
    module Tools
      ::RSpec.describe Stats do
        let(:event_store) { RubyEventStore::Client.new }
        let(:tool) { Stats.new }

        class OrderCreated < RubyEventStore::Event; end
        class OrderShipped < RubyEventStore::Event; end

        describe "#name" do
          it { expect(tool.name).to eq("stats") }
        end

        describe "#call" do
          it "shows total event count" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$1")
            result = tool.call(event_store, {})
            expect(result).to include("Events:  2")
          end

          it "lists unique event types" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$1")
            result = tool.call(event_store, {})
            expect(result).to include("OrderCreated")
            expect(result).to include("OrderShipped")
            expect(result.scan("OrderCreated").count).to eq(1)
          end

          it "shows per-stream stats when stream given" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$2")
            result = tool.call(event_store, "stream" => "Order$1")
            expect(result).to include("Stream:  Order$1")
            expect(result).to include("Events:  1")
            expect(result).not_to include("OrderShipped")
          end

          it "omits event types section for empty store" do
            result = tool.call(event_store, {})
            expect(result).not_to include("Event types")
          end
        end
      end
    end
  end
end
