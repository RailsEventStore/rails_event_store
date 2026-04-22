# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/stream_events"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe StreamEvents do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { StreamEvents.new }

        before { EventStoreResolver.event_store = event_store }

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
        end
      end
    end
  end
end
