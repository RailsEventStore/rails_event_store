# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/follow"

module RubyEventStore
  module CLI
    module Commands
      class FollowOrdering < RubyEventStore::Event; end
      class FollowOrderConfirmed < RubyEventStore::Event; end
      class FollowPayment < RubyEventStore::Event; end
      class FollowInventory < RubyEventStore::Event; end

      RSpec.describe Follow do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { Follow.new }
        let(:past) { (Time.now - 3600).iso8601(3) }

        before { stub_event_store(event_store) }

        def call_once(**opts)
          begin
            command.call(limit: 5, interval: 1, follow: false, since: past, **opts)
          rescue SystemExit
          end
        end

        describe "#call with --no-follow" do
          it "shows nothing when no events" do
            expect { call_once }.to output(/No events yet/).to_stdout
          end

          it "shows events grouped by namespace" do
            event_store.publish(FollowOrdering.new, stream_name: "test")

            expect { call_once }.to output(/FollowOrdering/).to_stdout
          end

          it "groups events under namespace header" do
            event_store.publish(FollowOrdering.new, stream_name: "test")
            event_store.publish(FollowOrderConfirmed.new, stream_name: "test")

            output = capture_stdout { call_once }
            expect(output.lines.count { |l| l.include?("RubyEventStore") && l.include?("events") }).to eq(1)
          end

          it "filters by namespace" do
            event_store.publish(FollowOrdering.new, stream_name: "test")
            event_store.publish(FollowPayment.new, stream_name: "test")

            output = capture_stdout { call_once(namespace: "RubyEventStore") }
            expect(output).to include("RubyEventStore")
          end

          it "excludes events outside requested namespace" do
            event_store.publish(FollowOrdering.new, stream_name: "test")
            event_store.publish(FollowPayment.new, stream_name: "test")

            output = capture_stdout { call_once(namespace: "Other") }
            expect(output).to include("No events yet")
          end

          it "shows last N events per namespace when limit exceeded" do
            10.times { event_store.publish(FollowOrdering.new, stream_name: "test") }

            output = capture_stdout { call_once(limit: 3) }
            event_lines = output.lines.select { |l| l.start_with?("  ") }
            expect(event_lines.size).to eq(3)
          end

          it "places events without namespace under Other" do
            expect(command.send(:namespace, "OrderPlaced")).to eq("Other")
          end

          it "does not show follow footer" do
            expect { call_once }.not_to output(/Press Ctrl\+C/).to_stdout
          end

          it "does not show events older than --since" do
            newer_since = (Time.now + 3600).iso8601(3)
            event_store.publish(FollowOrdering.new, stream_name: "test")

            expect { call_once(since: newer_since) }.to output(/No events yet/).to_stdout
          end
        end

        describe "#call with --follow" do
          it "shows follow footer" do
            allow(command).to receive(:sleep) { raise StopIteration }

            expect {
              begin
                command.call(limit: 5, interval: 1, follow: true, since: past)
              rescue SystemExit
              end
            }.to output(/Press Ctrl\+C/).to_stdout
          end

          it "exits cleanly on Interrupt" do
            allow(command).to receive(:sleep) { raise Interrupt }

            expect {
              command.call(limit: 5, interval: 1, follow: true, since: past)
            }.to raise_error(SystemExit) { |e| expect(e.status).to eq(0) }
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
