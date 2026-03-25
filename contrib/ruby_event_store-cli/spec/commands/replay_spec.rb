# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/replay"

module RubyEventStore
  module CLI
    module Commands
      class FakeHandler
        def self.call(event)
          @calls ||= []
          @calls << event
        end

        def self.calls
          @calls || []
        end

        def self.reset
          @calls = []
        end
      end

      RSpec.describe Replay do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { Replay.new }

        before do
          EventStoreResolver.event_store = event_store
          FakeHandler.reset
        end

        describe "#call" do
          it "calls handler for each event in the stream" do
            3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream") }

            command.call(stream: "test-stream", handler: "RubyEventStore::CLI::Commands::FakeHandler", dry_run: false)

            expect(FakeHandler.calls.size).to eq(3)
          end

          it "prints confirmation after replay" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")

            expect { command.call(stream: "test-stream", handler: "RubyEventStore::CLI::Commands::FakeHandler", dry_run: false) }
              .to output(/Replayed 1 event\(s\)/).to_stdout
          end

          it "shows count in dry-run without calling handler" do
            3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream") }

            expect { command.call(stream: "test-stream", handler: "RubyEventStore::CLI::Commands::FakeHandler", dry_run: true) }
              .to output(/Would replay 3 event\(s\)/).to_stdout

            expect(FakeHandler.calls).to be_empty
          end

          it "prints message for empty stream" do
            expect { command.call(stream: "empty", handler: "RubyEventStore::CLI::Commands::FakeHandler", dry_run: false) }
              .to output(/no events/).to_stdout
          end

          it "prints friendly error for unknown handler" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")

            expect {
              begin
                command.call(stream: "test-stream", handler: "NonExistentHandler", dry_run: false)
              rescue SystemExit
              end
            }.to output(/Unknown handler: NonExistentHandler/).to_stderr
          end

          it "prints error when handler does not respond to .call" do
            stub_const("BadHandler", Class.new)

            expect {
              begin
                command.call(stream: "test-stream", handler: "BadHandler", dry_run: false)
              rescue SystemExit
              end
            }.to output(/does not respond to .call/).to_stderr
          end
        end
      end
    end
  end
end
