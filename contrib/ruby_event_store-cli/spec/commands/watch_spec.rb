# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/watch"

module RubyEventStore
  module CLI
    module Commands
      class WatchOrdering < RubyEventStore::Event; end
      class WatchOrderConfirmed < RubyEventStore::Event; end
      class WatchPayment < RubyEventStore::Event; end

      RSpec.describe Watch do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { Watch.new }
        let(:past) { (Time.now - 3600).iso8601(3) }
        let(:since) { Time.now - 3600 }

        before { stub_const("RubyEventStore::CLI::EVENT_STORE", event_store) }

        def call_once(**opts)
          allow(command).to receive(:sleep) { raise StopIteration }
          begin
            command.call(limit: 50, interval: 1, since: past, **opts)
          rescue SystemExit
          end
        end

        describe "prepare" do
          it "returns events grouped by namespace" do
            event_store.publish(WatchOrdering.new, stream_name: "test")
            event_store.publish(WatchPayment.new, stream_name: "test")

            grouped = command.send(:prepare, event_store, since: since, namespaces: nil)
            expect(grouped.map(&:first)).to eq(["RubyEventStore"])
            expect(grouped.first[1].size).to eq(2)
          end

          it "filters by namespaces" do
            event_store.publish(WatchOrdering.new, stream_name: "test")
            event_store.publish(WatchPayment.new, stream_name: "test")

            grouped = command.send(:prepare, event_store, since: since, namespaces: ["Other"])
            expect(grouped).to be_empty
          end

          it "returns empty when no events" do
            grouped = command.send(:prepare, event_store, since: since, namespaces: nil)
            expect(grouped).to be_empty
          end

          it "excludes events older than since" do
            event_store.publish(WatchOrdering.new, stream_name: "test")
            future = Time.now + 3600

            grouped = command.send(:prepare, event_store, since: future, namespaces: nil)
            expect(grouped).to be_empty
          end
        end

        describe "render" do
          it "shows no events message when grouped is empty" do
            expect { command.send(:render, [], limit: 5, since: since) }
              .to output(/No events yet/).to_stdout
          end

          it "shows namespace header with event count" do
            grouped = [["Ordering", [{ event_id: "abc", type: "Ordering::OrderPlaced", timestamp: Time.now }]]]

            expect { command.send(:render, grouped, limit: 5, since: since) }
              .to output(/Ordering \(1 events\)/).to_stdout
          end

          it "shows short type name" do
            grouped = [["Ordering", [{ event_id: "abc", type: "Ordering::OrderPlaced", timestamp: Time.now }]]]

            expect { command.send(:render, grouped, limit: 5, since: since) }
              .to output(/OrderPlaced/).to_stdout
          end

          it "shows last N events per namespace" do
            events = 10.times.map { |i| { event_id: "id-#{i}", type: "Ordering::OrderPlaced", timestamp: Time.now } }
            grouped = [["Ordering", events]]

            output = capture_stdout { command.send(:render, grouped, limit: 3, since: since) }
            event_lines = output.lines.select { |l| l.start_with?("  ") }
            expect(event_lines.size).to eq(3)
          end

          it "always shows follow footer" do
            expect { command.send(:render, [], limit: 5, since: since) }
              .to output(/Press Ctrl\+C/).to_stdout
          end
        end

        describe "#call" do
          it "places events without namespace under Other" do
            expect(command.send(:namespace, "OrderPlaced")).to eq("Other")
          end

          it "exits cleanly on Interrupt" do
            allow(command).to receive(:sleep) { raise Interrupt }

            expect {
              command.call(limit: 5, interval: 1, since: past)
            }.to raise_error(SystemExit) { |e| expect(e.status).to eq(0) }
          end

          it "renders grouped events from event store" do
            event_store.publish(WatchOrdering.new, stream_name: "test")

            expect { call_once }.to output(/WatchOrdering/).to_stdout
          end
        end

        def capture_stdout
          out = StringIO.new
          $stdout = out
          yield
          out.string
        ensure
          $stdout = STDOUT
        end
      end
    end
  end
end
