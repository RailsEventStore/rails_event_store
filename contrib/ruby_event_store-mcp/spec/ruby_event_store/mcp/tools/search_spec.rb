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
        end
      end
    end
  end
end
