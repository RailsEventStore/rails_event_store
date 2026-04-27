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
          it "includes required stream_name property" do
            expect(tool.schema[:inputSchema][:required]).to include("stream_name")
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
            event_store.publish(RubyEventStore::Event.new, stream_name: "Order$1")
            event_store.publish(RubyEventStore::Event.new, stream_name: "Order$1")
            result = tool.call(event_store, "stream_name" => "Order$1")
            expect(result).to include("Version: 1")
          end

          it "shows first and last event types" do
            event_store.publish(OrderCreated.new, stream_name: "Order$1")
            event_store.publish(OrderShipped.new, stream_name: "Order$1")
            result = tool.call(event_store, "stream_name" => "Order$1")
            expect(result).to match(/First:.*OrderCreated/)
            expect(result).to match(/Last:.*OrderShipped/)
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
