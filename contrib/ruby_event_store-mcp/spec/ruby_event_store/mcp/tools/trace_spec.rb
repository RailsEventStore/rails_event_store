# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp/tools/trace"

module RubyEventStore
  module MCP
    module Tools
      ::RSpec.describe Trace do
        class OrderPlaced < RubyEventStore::Event; end
        class PaymentProcessed < RubyEventStore::Event; end
        class OrderShipped < RubyEventStore::Event; end
        class UserRegistered < RubyEventStore::Event; end
        class FraudCheckPassed < RubyEventStore::Event; end
        class InventoryReserved < RubyEventStore::Event; end
        class InventoryReleased < RubyEventStore::Event; end
        class WarehouseNotified < RubyEventStore::Event; end
        class InvoiceGenerated < RubyEventStore::Event; end
        class LoyaltyPointsAwarded < RubyEventStore::Event; end
        class EmailSent < RubyEventStore::Event; end

        let(:event_store) { RubyEventStore::Client.new }
        let(:tool) { Trace.new }

        def pub(event, stream)
          event_store.publish(event, stream_name: stream)
          event_store.link(event.event_id, stream_name: "$by_correlation_id_#{event.metadata[:correlation_id]}")
          event
        end

        def tree_shape(cid)
          tool.call(event_store, "correlation_id" => cid)
            .lines.map(&:chomp)
            .map { |l| l.sub(/(?:\w+::)+(\w+) \[/, '\1 [').sub(/\[.*?\]/, "[id]") }
        end

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
            cid = SecureRandom.uuid
            expect(tool.call(event_store, "correlation_id" => cid)).to include("correlation ID #{cid}")
          end

          context "chain: OrderPlaced → PaymentProcessed → OrderShipped" do
            let(:cid) { SecureRandom.uuid }
            let!(:order)   { pub(OrderPlaced.new(metadata: { correlation_id: cid }), "Order$1") }
            let!(:payment) { pub(PaymentProcessed.new(metadata: { correlation_id: cid, causation_id: order.event_id }), "Payment$1") }
            let!(:shipped) { pub(OrderShipped.new(metadata: { correlation_id: cid, causation_id: payment.event_id }), "Order$1") }

            it "renders the causation chain" do
              expect(tree_shape(cid)).to eq([
                "OrderPlaced [id]",
                "└── PaymentProcessed [id]",
                "    └── OrderShipped [id]"
              ])
            end

            it "root and last-child lines include the actual event_id" do
              lines = tool.call(event_store, "correlation_id" => cid).lines.map(&:chomp)
              expect(lines[0]).to match(/OrderPlaced \[#{order.event_id}\]/)
              expect(lines[1]).to match(/└── .*PaymentProcessed \[#{payment.event_id}\]/)
            end

            it "only includes events from the given correlation id stream" do
              pub(OrderPlaced.new(metadata: { correlation_id: SecureRandom.uuid }), "Other$1")
              expect(tool.call(event_store, "correlation_id" => cid).lines.count).to eq(3)
            end
          end

          context "branching: OrderPlaced → [PaymentProcessed → OrderShipped, UserRegistered]" do
            let(:cid) { SecureRandom.uuid }
            let!(:order)      { pub(OrderPlaced.new(metadata: { correlation_id: cid }), "Order$2") }
            let!(:payment)    { pub(PaymentProcessed.new(metadata: { correlation_id: cid, causation_id: order.event_id }), "Payment$2") }
            let!(:registered) { pub(UserRegistered.new(metadata: { correlation_id: cid, causation_id: order.event_id }), "User$2") }
            let!(:shipped)    { pub(OrderShipped.new(metadata: { correlation_id: cid, causation_id: payment.event_id }), "Order$2") }

            it "renders the branching tree" do
              expect(tree_shape(cid)).to eq([
                "OrderPlaced [id]",
                "├── PaymentProcessed [id]",
                "│   └── OrderShipped [id]",
                "└── UserRegistered [id]"
              ])
            end

            it "non-last branch line contains event_type and event_id" do
              lines = tool.call(event_store, "correlation_id" => cid).lines.map(&:chomp)
              non_last_line = lines.find { |l| l.include?("├──") }
              expect(non_last_line).to match(/├── .*PaymentProcessed \[#{payment.event_id}\]/)
            end
          end

          context "full order flow with deep branching" do
            let(:cid) { SecureRandom.uuid }
            let!(:order)         { pub(OrderPlaced.new(metadata: { correlation_id: cid }), "Order$3") }
            let!(:fraud)         { pub(FraudCheckPassed.new(metadata: { correlation_id: cid, causation_id: order.event_id }), "Fraud$3") }
            let!(:inv_reserved)  { pub(InventoryReserved.new(metadata: { correlation_id: cid, causation_id: order.event_id }), "Inventory$3") }
            let!(:payment)       { pub(PaymentProcessed.new(metadata: { correlation_id: cid, causation_id: fraud.event_id }), "Payment$3") }
            let!(:invoice)       { pub(InvoiceGenerated.new(metadata: { correlation_id: cid, causation_id: payment.event_id }), "Invoice$3") }
            let!(:loyalty)       { pub(LoyaltyPointsAwarded.new(metadata: { correlation_id: cid, causation_id: payment.event_id }), "Loyalty$3") }
            let!(:warehouse)     { pub(WarehouseNotified.new(metadata: { correlation_id: cid, causation_id: payment.event_id }), "Warehouse$3") }
            let!(:shipped)       { pub(OrderShipped.new(metadata: { correlation_id: cid, causation_id: warehouse.event_id }), "Order$3") }
            let!(:email_confirm) { pub(EmailSent.new(metadata: { correlation_id: cid, causation_id: warehouse.event_id }), "Email$3") }
            let!(:inv_released)  { pub(InventoryReleased.new(metadata: { correlation_id: cid, causation_id: shipped.event_id }), "Inventory$3") }
            let!(:email_delivery){ pub(EmailSent.new(metadata: { correlation_id: cid, causation_id: shipped.event_id }), "Email$3") }

            it "renders the full order flow tree" do
              expect(tree_shape(cid)).to eq([
                "OrderPlaced [id]",
                "├── FraudCheckPassed [id]",
                "│   └── PaymentProcessed [id]",
                "│       ├── InvoiceGenerated [id]",
                "│       ├── LoyaltyPointsAwarded [id]",
                "│       └── WarehouseNotified [id]",
                "│           ├── OrderShipped [id]",
                "│           │   ├── InventoryReleased [id]",
                "│           │   └── EmailSent [id]",
                "│           └── EmailSent [id]",
                "└── InventoryReserved [id]"
              ])
            end

            it "accumulates prefix across deeply nested non-last nodes" do
              lines = tool.call(event_store, "correlation_id" => cid).lines.map(&:chomp)
              inv_released_line = lines.find { |l| l.include?(inv_released.event_id) }
              expect(inv_released_line).to start_with("│           │   ├──")
            end
          end

          it "treats event with external causation_id as a root" do
            cid = SecureRandom.uuid
            pub(OrderPlaced.new(metadata: { correlation_id: cid, causation_id: SecureRandom.uuid }), "Order$4")
            expect(tree_shape(cid)).to eq(["OrderPlaced [id]"])
          end

          it "shows multiple root events each without connector prefix" do
            cid = SecureRandom.uuid
            pub(OrderPlaced.new(metadata: { correlation_id: cid }), "Order$5")
            pub(PaymentProcessed.new(metadata: { correlation_id: cid }), "Payment$5")

            lines = tool.call(event_store, "correlation_id" => cid).lines.map(&:chomp)
            expect(lines.count).to eq(2)
            lines.each { |l| expect(l).not_to match(/[├└]/) }
          end
        end
      end
    end
  end
end
