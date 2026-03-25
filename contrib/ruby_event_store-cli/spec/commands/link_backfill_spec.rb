# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/link_backfill"

module RubyEventStore
  module CLI
    module Commands
      class BackfillEvent < RubyEventStore::Event; end
      class OtherBackfillEvent < RubyEventStore::Event; end

      RSpec.describe LinkBackfill do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { LinkBackfill.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "links all events of given type to the target stream" do
            3.times { event_store.publish(BackfillEvent.new, stream_name: "source") }
            event_store.publish(OtherBackfillEvent.new, stream_name: "source")

            begin
              command.call(type: "RubyEventStore::CLI::Commands::BackfillEvent", stream: "target", dry_run: false)
            rescue SystemExit
            end

            events = event_store.read.stream("target").to_a
            expect(events.size).to eq(3)
            expect(events.map(&:event_type).uniq).to eq(["RubyEventStore::CLI::Commands::BackfillEvent"])
          end

          it "prints linked count" do
            3.times { event_store.publish(BackfillEvent.new, stream_name: "source") }

            expect {
              begin
                command.call(type: "RubyEventStore::CLI::Commands::BackfillEvent", stream: "target", dry_run: false)
              rescue SystemExit
              end
            }.to output(/Linked 3 event\(s\)/).to_stdout
          end

          it "skips already linked events" do
            event = BackfillEvent.new
            event_store.publish(event, stream_name: "source")
            event_store.link(event.event_id, stream_name: "target")

            expect {
              begin
                command.call(type: "RubyEventStore::CLI::Commands::BackfillEvent", stream: "target", dry_run: false)
              rescue SystemExit
              end
            }.to output(/skipped 1 \(already linked\)/).to_stdout
          end

          it "reports count in dry-run mode without linking" do
            3.times { event_store.publish(BackfillEvent.new, stream_name: "source") }

            expect {
              begin
                command.call(type: "RubyEventStore::CLI::Commands::BackfillEvent", stream: "target", dry_run: true)
              rescue SystemExit
              end
            }.to output(/Would link 3 event\(s\)/).to_stdout

            expect(event_store.read.stream("target").to_a).to be_empty
          end

          it "does not link in dry-run mode" do
            3.times { event_store.publish(BackfillEvent.new, stream_name: "source") }

            begin
              command.call(type: "RubyEventStore::CLI::Commands::BackfillEvent", stream: "target", dry_run: true)
            rescue SystemExit
            end

            expect(event_store.read.stream("target").to_a).to be_empty
          end

          it "only links events from source stream when --source-stream given" do
            event_in_source = BackfillEvent.new
            event_outside   = BackfillEvent.new
            event_store.publish(event_in_source, stream_name: "source")
            event_store.publish(event_outside, stream_name: "other")

            begin
              command.call(type: "RubyEventStore::CLI::Commands::BackfillEvent", stream: "target", dry_run: false, source_stream: "source")
            rescue SystemExit
            end

            linked_ids = event_store.read.stream("target").to_a.map(&:event_id)
            expect(linked_ids).to eq([event_in_source.event_id])
          end

          it "prints friendly error for unknown event type" do
            expect {
              begin
                command.call(type: "NonExistent", stream: "target", dry_run: false)
              rescue SystemExit
              end
            }.to output(/Unknown event type: NonExistent/).to_stderr
          end
        end
      end
    end
  end
end
