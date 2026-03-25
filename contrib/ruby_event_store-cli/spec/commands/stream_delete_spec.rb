# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/stream_delete"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe StreamDelete do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { StreamDelete.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "deletes the stream with --force" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "to-delete")

            command.call(stream_name: "to-delete", dry_run: false, force: true)

            expect(event_store.read.stream("to-delete").count).to eq(0)
          end

          it "prints confirmation after deletion" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "to-delete")

            expect { command.call(stream_name: "to-delete", dry_run: false, force: true) }
              .to output(/Deleted stream 'to-delete'/).to_stdout
          end

          it "shows what would be deleted in dry-run mode" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "to-delete")

            expect { command.call(stream_name: "to-delete", dry_run: true, force: false) }
              .to output(/Would delete stream 'to-delete'/).to_stdout

            expect(event_store.read.stream("to-delete").count).to eq(1)
          end

          it "prints error for empty or non-existent stream" do
            expect {
              begin
                command.call(stream_name: "non-existent", dry_run: false, force: true)
              rescue SystemExit
              end
            }.to output(/non-existent/).to_stderr
          end

          it "prompts for confirmation without --force" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "to-delete")
            allow($stdin).to receive(:gets).and_return("y\n")

            command.call(stream_name: "to-delete", dry_run: false, force: false)

            expect(event_store.read.stream("to-delete").count).to eq(0)
          end

          it "aborts when confirmation is declined" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "to-delete")
            allow($stdin).to receive(:gets).and_return("n\n")

            expect { command.call(stream_name: "to-delete", dry_run: false, force: false) }
              .to output(/Aborted/).to_stdout

            expect(event_store.read.stream("to-delete").count).to eq(1)
          end
        end
      end
    end
  end
end
