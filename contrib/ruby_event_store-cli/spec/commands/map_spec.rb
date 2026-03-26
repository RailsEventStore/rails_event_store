# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/map"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe Map do
        include_context "with AR database"
        let(:event_store) { ar_event_store }
        let(:command) { Map.new }

        before { EventStoreResolver.event_store = event_store }

        def call
          begin
            command.call
          rescue SystemExit
          end
        end

        describe "#call" do
          it "shows bounded context with aggregate" do
            event_store.publish(Event.new, stream_name: "Ordering::Order$abc-123")

            expect { call }.to output(/Ordering/).to_stdout
            expect { call }.to output(/Order/).to_stdout
          end

          it "shows multiple bounded contexts" do
            event_store.publish(Event.new, stream_name: "Ordering::Order$abc-123")
            event_store.publish(Event.new, stream_name: "Payments::Payment$abc-123")

            expect { call }.to output(/Ordering/).to_stdout
            expect { call }.to output(/Payments/).to_stdout
          end

          it "deduplicates aggregates across instances" do
            event_store.publish(Event.new, stream_name: "Ordering::Order$uuid-1")
            event_store.publish(Event.new, stream_name: "Ordering::Order$uuid-2")

            output = StringIO.new
            $stdout = output
            call
            $stdout = STDOUT
            expect(output.string.lines.count { |l| l.strip == "Order" }).to eq(1)
          end

          it "shows process managers" do
            event_store.publish(Event.new, stream_name: "Processes::ShipmentProcess$abc-123")

            expect { call }.to output(/Process Managers/).to_stdout
            expect { call }.to output(/ShipmentProcess/).to_stdout
          end

          it "does not show Processes as a bounded context" do
            event_store.publish(Event.new, stream_name: "Processes::ShipmentProcess$abc-123")

            expect { call }.not_to output(/Bounded Contexts.*Processes/m).to_stdout
          end

          it "shows read models with source event types" do
            event_store.publish(Event.new, stream_name: "Products::Product$uuid-1$Ordering::OrderPlaced")

            expect { call }.to output(/Read Models/).to_stdout
            expect { call }.to output(/Ordering::OrderPlaced/).to_stdout
          end

          it "deduplicates read model event types across instances" do
            event_store.publish(Event.new, stream_name: "Products::Product$uuid-1$Ordering::OrderPlaced")
            event_store.publish(Event.new, stream_name: "Products::Product$uuid-2$Ordering::OrderPlaced")

            expect { call }.to output(/Ordering::OrderPlaced/).to_stdout
            expect { call }.not_to output(/Ordering::OrderPlaced.*Ordering::OrderPlaced/m).to_stdout
          end

          it "skips system streams" do
            event_store.publish(Event.new, stream_name: "Ordering::Order$abc-123")

            expect { call }.not_to output(/\$by_correlation/).to_stdout
            expect { call }.not_to output(/\$by_causation/).to_stdout
          end

          it "shows nothing when store is empty" do
            expect { call }.not_to output(/Bounded Contexts/).to_stdout
            expect { call }.not_to output(/Process Managers/).to_stdout
            expect { call }.not_to output(/Read Models/).to_stdout
          end
        end
      end
    end
  end
end
