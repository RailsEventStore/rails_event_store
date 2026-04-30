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
          it "requires event_id" do
            expect(tool.schema[:inputSchema][:required]).to include("event_id")
          end
        end

        describe "#call" do
          it "shows event details" do
            event = OrderCreated.new(data: { order_id: 42 })
            event_store.publish(event, stream_name: "Order$42")

            result = tool.call(event_store, "event_id" => event.event_id)

            expect(result).to include("Event ID:   #{event.event_id}")
            expect(result).to include("Type:       RubyEventStore::MCP::Tools::OrderCreated")
            expect(result).to include("order_id")
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
