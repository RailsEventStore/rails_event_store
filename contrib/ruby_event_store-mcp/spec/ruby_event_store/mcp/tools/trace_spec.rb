# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp/tools/trace"

module RubyEventStore
  module MCP
    module Tools
      ::RSpec.describe Trace do
        let(:event_store) { RubyEventStore::Client.new }
        let(:tool) { Trace.new }

        class OrderCreated < RubyEventStore::Event; end
        class PaymentCharged < RubyEventStore::Event; end
        class EmailSent < RubyEventStore::Event; end

        describe "#name" do
          it { expect(tool.name).to eq("trace") }
        end

        describe "#schema" do
          it "requires correlation_id" do
            expect(tool.schema[:inputSchema][:required]).to include("correlation_id")
          end
        end

        describe "#call" do
          it "returns no events message for unknown correlation id" do
            result = tool.call(event_store, "correlation_id" => SecureRandom.uuid)
            expect(result).to include("no events found")
          end

          it "shows root event" do
            correlation_id = SecureRandom.uuid
            root = OrderCreated.new(metadata: { correlation_id: correlation_id })
            event_store.publish(root, stream_name: "Order$1")
            event_store.link(root.event_id, stream_name: "$by_correlation_id_#{correlation_id}")

            result = tool.call(event_store, "correlation_id" => correlation_id)
            expect(result).to include("OrderCreated")
            expect(result).to include(root.event_id)
          end

          it "shows causation tree with children" do
            correlation_id = SecureRandom.uuid
            root = OrderCreated.new(metadata: { correlation_id: correlation_id })
            child = PaymentCharged.new(metadata: { correlation_id: correlation_id, causation_id: root.event_id })
            grandchild = EmailSent.new(metadata: { correlation_id: correlation_id, causation_id: child.event_id })

            event_store.publish(root, stream_name: "Order$1")
            event_store.publish(child, stream_name: "Payment$1")
            event_store.publish(grandchild, stream_name: "Email$1")
            [root, child, grandchild].each do |e|
              event_store.link(e.event_id, stream_name: "$by_correlation_id_#{correlation_id}")
            end

            result = tool.call(event_store, "correlation_id" => correlation_id)
            lines = result.lines.map(&:chomp)

            expect(lines[0]).to match(/OrderCreated \[/)
            expect(lines[1]).to match(/└──.*PaymentCharged \[/)
            expect(lines[2]).to match(/    └──.*EmailSent \[/)
          end
        end
      end
    end
  end
end
