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
          it "requires stream_name" do
            expect(tool.schema[:inputSchema][:required]).to include("stream_name")
          end
        end

        describe "#call" do
          it "returns no events message for empty stream" do
            expect(tool.call(event_store, "stream_name" => "empty")).to eq("(no events)")
          end

          it "lists events with timestamp, type and id" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            result = tool.call(event_store, "stream_name" => "Order$1")
            expect(result).to match(/OrderCreated/)
            expect(result).to match(/\[.{36}\]/)
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

          it "raises for unknown event type" do
            expect { tool.call(event_store, "stream_name" => "Order$1", "type" => "NonExistentType") }
              .to raise_error(/Unknown event type/)
          end
        end
      end
    end
  end
end
