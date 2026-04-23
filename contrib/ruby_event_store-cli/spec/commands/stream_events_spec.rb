# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/stream_events"

module RubyEventStore
  module CLI
    module Commands
      class OtherEvent < RubyEventStore::Event; end

      RSpec.describe StreamEvents do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { StreamEvents.new }

        before { stub_event_store(event_store) }

        describe "#call" do
          it "reads events from given stream" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")

            expect { command.call(stream_name: "test-stream", limit: 50, format: "table") }
              .to output(/test-stream|RubyEventStore::Event/).to_stdout
          end

          it "respects limit" do
            5.times { event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream") }

            expect { command.call(stream_name: "test-stream", limit: 2, format: "table") }
              .to output(/2 event\(s\)/).to_stdout
          end

          it "outputs json when format is json" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")

            expect { command.call(stream_name: "test-stream", limit: 50, format: "json") }
              .to output(/event_id/).to_stdout
          end

          it "prints message when stream is empty" do
            expect { command.call(stream_name: "empty-stream", limit: 50, format: "table") }
              .to output(/no events/).to_stdout
          end

          it "filters by event type" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")
            event_store.publish(OtherEvent.new, stream_name: "test-stream")

            expect { command.call(stream_name: "test-stream", limit: 50, format: "table", type: "RubyEventStore::CLI::Commands::OtherEvent") }
              .to output(/1 event\(s\)/).to_stdout
          end

          it "filters by --after timestamp excluding past events" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")
            future = (Time.now + 3600).iso8601(3)

            expect { command.call(stream_name: "test-stream", limit: 50, format: "table", after: future) }
              .to output(/no events/).to_stdout
          end

          it "filters by --before timestamp excluding future events" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")
            past = (Time.now - 3600).iso8601(3)

            expect { command.call(stream_name: "test-stream", limit: 50, format: "table", before: past) }
              .to output(/no events/).to_stdout
          end

          it "shows friendly error for unknown event type" do
            expect {
              begin
                command.call(stream_name: "test-stream", limit: 50, format: "table", type: "NonExistent::Event")
              rescue SystemExit
              end
            }.to output(/Unknown event type: NonExistent::Event/).to_stderr
          end

          it "starts from given event id" do
            e1 = RubyEventStore::Event.new
            e2 = RubyEventStore::Event.new
            e3 = RubyEventStore::Event.new
            event_store.publish([e1, e2, e3], stream_name: "test-stream")

            expect { command.call(stream_name: "test-stream", limit: 50, format: "table", from: e1.event_id) }
              .to output(/2 event\(s\)/).to_stdout
          end
          context "--follow" do
            it "prints existing events before watching" do
              event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")
              allow(command).to receive(:sleep) { raise StopIteration }

              expect {
                begin
                  command.call(stream_name: "test-stream", limit: 50, format: "table", follow: true)
                rescue SystemExit
                end
              }.to output(/RubyEventStore::Event/).to_stdout
            end

            it "prints new events published after initial read" do
              e1 = RubyEventStore::Event.new
              e2 = RubyEventStore::Event.new
              event_store.publish(e1, stream_name: "test-stream")
              call_count = 0
              allow(command).to receive(:sleep) do
                call_count += 1
                event_store.publish(e2, stream_name: "test-stream") if call_count == 1
                raise StopIteration if call_count >= 2
              end

              output = StringIO.new
              $stdout = output
              begin
                command.call(stream_name: "test-stream", limit: 50, format: "table", follow: true)
              rescue SystemExit
              end
              $stdout = STDOUT

              expect(output.string).to include(e1.event_id)
              expect(output.string).to include(e2.event_id)
            end

            it "exits cleanly on Interrupt" do
              allow(command).to receive(:sleep) { raise Interrupt }

              expect {
                command.call(stream_name: "test-stream", limit: 50, format: "table", follow: true)
              }.to raise_error(SystemExit) { |e| expect(e.status).to eq(0) }
            end
          end
        end
      end
    end
  end
end
