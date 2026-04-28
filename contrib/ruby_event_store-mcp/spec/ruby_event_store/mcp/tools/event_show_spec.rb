# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp/tools/event_show"

module RubyEventStore
  module MCP
    module Tools
      ::RSpec.describe EventShow do
        let(:event_store) { RubyEventStore::Client.new }
        let(:tool) { EventShow.new }

        class OrderCreated < RubyEventStore::Event; end

        describe "#name" do
          it { expect(tool.name).to eq("event_show") }
        end

        describe "#schema" do
          it "has expected structure" do
            expect(tool.schema).to eq(
              name: "event_show",
              description: "Show full event details including data, metadata, and timestamps",
              inputSchema: {
                type: "object",
                properties: { event_id: { type: "string", description: "Event ID (UUID)" } },
                required: ["event_id"]
              }
            )
          end
        end

        describe "#call" do
          let(:event) { OrderCreated.new(data: { order_id: 42 }, metadata: { user_id: 1 }) }
          let(:result) { event_store.publish(event, stream_name: "Order$42"); tool.call(event_store, "event_id" => event.event_id) }

          it "shows event id" do
            expect(result).to include("Event ID:   #{event.event_id}")
          end

          it "shows event type" do
            expect(result).to include("Type:       RubyEventStore::MCP::Tools::OrderCreated")
          end

          it "shows timestamp in iso8601 with exactly 3 decimal places" do
            expect(result).to match(/Timestamp:  \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z/)
          end

          it "shows valid_at in iso8601 with exactly 3 decimal places" do
            expect(result).to match(/Valid at:   \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z/)
          end

          it "shows data as formatted json" do
            expect(result).to include('"order_id": 42')
          end

          it "shows metadata as formatted json" do
            expect(result).to include('"user_id": 1')
          end

          it "separates fields with newlines between each field" do
            expect(result.lines.first.chomp).to eq("Event ID:   #{event.event_id}")
            expect(result.lines[1].chomp).to start_with("Type:")
          end

          it "raises for unknown event" do
            expect { tool.call(event_store, "event_id" => SecureRandom.uuid) }
              .to raise_error(RubyEventStore::EventNotFound)
          end
        end
      end
    end
  end
end
