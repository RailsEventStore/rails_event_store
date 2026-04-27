# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp/tools/event_streams"

module RubyEventStore
  module MCP
    module Tools
      ::RSpec.describe EventStreams do
        let(:event_store) { RubyEventStore::Client.new }
        let(:tool) { EventStreams.new }

        describe "#name" do
          it { expect(tool.name).to eq("event_streams") }
        end

        describe "#schema" do
          it "requires event_id" do
            expect(tool.schema[:inputSchema][:required]).to include("event_id")
          end
        end

        describe "#call" do
          it "returns no streams message for unknown event" do
            result = tool.call(event_store, "event_id" => SecureRandom.uuid)
            expect(result).to include("no streams")
          end

          it "lists streams the event was published or linked to" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "Order$1")
            event_store.link(event.event_id, stream_name: "Shipping$1")

            result = tool.call(event_store, "event_id" => event.event_id)

            expect(result).to include("Order$1")
            expect(result).to include("Shipping$1")
          end
        end
      end
    end
  end
end
