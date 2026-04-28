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
          it "has expected structure" do
            expect(tool.schema).to eq(
              name: "trace",
              description: "Show the causation tree for all events sharing a correlation ID",
              inputSchema: {
                type: "object",
                properties: {
                  correlation_id: { type: "string", description: "Correlation ID (UUID)" }
                },
                required: ["correlation_id"]
              }
            )
          end
        end

        describe "#call" do
          it "returns no events message for unknown correlation id" do
            result = tool.call(event_store, "correlation_id" => SecureRandom.uuid)
            expect(result).to include("no events found")
          end

          it "includes the correlation id in the no events message" do
            correlation_id = SecureRandom.uuid
            result = tool.call(event_store, "correlation_id" => correlation_id)
            expect(result).to include("correlation ID #{correlation_id}")
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

          it "shows root event without connector prefix" do
            correlation_id = SecureRandom.uuid
            root = OrderCreated.new(metadata: { correlation_id: correlation_id })
            event_store.publish(root, stream_name: "Order$1")
            event_store.link(root.event_id, stream_name: "$by_correlation_id_#{correlation_id}")

            result = tool.call(event_store, "correlation_id" => correlation_id)
            first_line = result.lines.first.chomp
            expect(first_line).not_to include("└──")
            expect(first_line).not_to include("├──")
          end

          it "only includes events from the given correlation id stream" do
            correlation_id = SecureRandom.uuid
            root = OrderCreated.new(metadata: { correlation_id: correlation_id })
            unrelated = PaymentCharged.new
            event_store.publish(root, stream_name: "Order$1")
            event_store.publish(unrelated, stream_name: "Payment$1")
            event_store.link(root.event_id, stream_name: "$by_correlation_id_#{correlation_id}")

            result = tool.call(event_store, "correlation_id" => correlation_id)
            expect(result).to include("OrderCreated")
            expect(result).not_to include("PaymentCharged")
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

            expect(lines.count).to eq(3)
            expect(lines[0]).to match(/\A\S.*OrderCreated \[/)
            expect(lines[1]).to match(/\A└──.*PaymentCharged \[/)
            expect(lines[2]).to match(/\A    └──.*EmailSent \[/)
          end

          it "shows branch connector for non-last children" do
            correlation_id = SecureRandom.uuid
            root = OrderCreated.new(metadata: { correlation_id: correlation_id })
            child1 = PaymentCharged.new(metadata: { correlation_id: correlation_id, causation_id: root.event_id })
            child2 = EmailSent.new(metadata: { correlation_id: correlation_id, causation_id: root.event_id })

            event_store.publish(root, stream_name: "Order$1")
            event_store.publish(child1, stream_name: "Payment$1")
            event_store.publish(child2, stream_name: "Email$1")
            [root, child1, child2].each do |e|
              event_store.link(e.event_id, stream_name: "$by_correlation_id_#{correlation_id}")
            end

            result = tool.call(event_store, "correlation_id" => correlation_id)
            expect(result).to include("├──")
            expect(result).to include("└──")
          end

          it "treats event with external causation_id as root" do
            correlation_id = SecureRandom.uuid
            root = OrderCreated.new(metadata: {
              correlation_id: correlation_id,
              causation_id: SecureRandom.uuid
            })
            event_store.publish(root, stream_name: "Order$1")
            event_store.link(root.event_id, stream_name: "$by_correlation_id_#{correlation_id}")

            result = tool.call(event_store, "correlation_id" => correlation_id)
            expect(result).to include("OrderCreated")
          end

          it "preserves accumulated prefix for deeply nested nodes" do
            correlation_id = SecureRandom.uuid
            root = OrderCreated.new(metadata: { correlation_id: correlation_id })
            child1 = PaymentCharged.new(metadata: { correlation_id: correlation_id, causation_id: root.event_id })
            child2 = EmailSent.new(metadata: { correlation_id: correlation_id, causation_id: root.event_id })
            grandchild = OrderCreated.new(metadata: { correlation_id: correlation_id, causation_id: child1.event_id })
            great_grandchild = PaymentCharged.new(metadata: { correlation_id: correlation_id, causation_id: grandchild.event_id })

            [root, child1, child2, grandchild, great_grandchild].each do |e|
              event_store.publish(e, stream_name: "Order$1")
              event_store.link(e.event_id, stream_name: "$by_correlation_id_#{correlation_id}")
            end

            result = tool.call(event_store, "correlation_id" => correlation_id)
            lines = result.lines.map(&:chomp)
            expect(lines[3]).to start_with("│")
          end

          it "shows pipe prefix for children under non-last branch" do
            correlation_id = SecureRandom.uuid
            root = OrderCreated.new(metadata: { correlation_id: correlation_id })
            child1 = PaymentCharged.new(metadata: { correlation_id: correlation_id, causation_id: root.event_id })
            child2 = EmailSent.new(metadata: { correlation_id: correlation_id, causation_id: root.event_id })
            grandchild = OrderCreated.new(metadata: { correlation_id: correlation_id, causation_id: child1.event_id })

            [root, child1, child2, grandchild].each { |e| event_store.publish(e, stream_name: "Order$1") }
            [root, child1, child2, grandchild].each do |e|
              event_store.link(e.event_id, stream_name: "$by_correlation_id_#{correlation_id}")
            end

            result = tool.call(event_store, "correlation_id" => correlation_id)
            expect(result).to include("│")
          end
        end
      end
    end
  end
end
