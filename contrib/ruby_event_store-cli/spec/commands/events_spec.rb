# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/events"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe Events do
        include_context "with AR database"
        let(:event_store) { ar_event_store }
        let(:command) { Events.new }

        before { EventStoreResolver.event_store = event_store }

        def call_once(**opts)
          begin
            command.call(limit: 5, interval: 1, follow: false, **opts)
          rescue SystemExit
          end
        end

        describe "#call with --no-follow" do
          it "shows nothing when no events since start" do
            expect { call_once }.to output(/No events yet/).to_stdout
          end

          it "shows events published before call but after started_at" do
            allow(command).to receive(:fetch_events).and_return([
              { event_id: "abc-123", type: "Ordering::OrderPlaced", timestamp: Time.now }
            ])

            expect { call_once }.to output(/Ordering/).to_stdout
            expect { call_once }.to output(/OrderPlaced/).to_stdout
          end

          it "filters by namespace" do
            allow(command).to receive(:fetch_events).and_return([
              { event_id: "abc-123", type: "Ordering::OrderPlaced", timestamp: Time.now },
              { event_id: "def-456", type: "Payments::PaymentCaptured", timestamp: Time.now }
            ])

            expect { call_once(namespace: "Ordering") }.to output(/Ordering/).to_stdout
            expect { call_once(namespace: "Ordering") }.not_to output(/Payments/).to_stdout
          end

          it "filters by multiple namespaces" do
            allow(command).to receive(:fetch_events).and_return([
              { event_id: "abc-123", type: "Ordering::OrderPlaced", timestamp: Time.now },
              { event_id: "def-456", type: "Payments::PaymentCaptured", timestamp: Time.now },
              { event_id: "ghi-789", type: "Inventory::StockReserved", timestamp: Time.now }
            ])

            expect { call_once(namespace: "Ordering,Payments") }.to output(/Ordering/).to_stdout
            expect { call_once(namespace: "Ordering,Payments") }.to output(/Payments/).to_stdout
            expect { call_once(namespace: "Ordering,Payments") }.not_to output(/Inventory/).to_stdout
          end

          it "groups events by namespace" do
            allow(command).to receive(:fetch_events).and_return([
              { event_id: "abc-123", type: "Ordering::OrderPlaced", timestamp: Time.now },
              { event_id: "def-456", type: "Ordering::OrderConfirmed", timestamp: Time.now }
            ])

            output = StringIO.new
            $stdout = output
            call_once
            $stdout = STDOUT

            expect(output.string.lines.count { |l| l.include?("Ordering") && l.include?("events") }).to eq(1)
          end

          it "shows last N events per namespace when limit exceeded" do
            events = 10.times.map { |i| { event_id: "id-#{i}", type: "Ordering::OrderPlaced", timestamp: Time.now } }
            allow(command).to receive(:fetch_events).and_return(events)

            output = StringIO.new
            $stdout = output
            call_once(limit: 3)
            $stdout = STDOUT

            event_lines = output.string.lines.select { |l| l.start_with?("  ") && l.include?("id-") }
            expect(event_lines.size).to eq(3)
          end

          it "does not show follow footer without --follow" do
            allow(command).to receive(:fetch_events).and_return([])
            expect { call_once }.not_to output(/Press Ctrl\+C/).to_stdout
          end
        end

        describe "#call with --follow" do
          it "shows follow footer" do
            allow(command).to receive(:fetch_events).and_return([])
            allow(command).to receive(:sleep) { raise StopIteration }

            expect {
              begin
                command.call(limit: 5, interval: 1, follow: true)
              rescue SystemExit
              end
            }.to output(/Press Ctrl\+C/).to_stdout
          end

          it "exits cleanly on Interrupt" do
            allow(command).to receive(:fetch_events).and_return([])
            allow(command).to receive(:sleep) { raise Interrupt }

            expect {
              command.call(limit: 5, interval: 1, follow: true)
            }.to raise_error(SystemExit) { |e| expect(e.status).to eq(0) }
          end
        end
      end
    end
  end
end
