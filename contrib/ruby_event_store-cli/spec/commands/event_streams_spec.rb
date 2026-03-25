# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/event_streams"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe EventStreams do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { EventStreams.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "lists streams containing the event" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "Orders")
            event_store.link(event.event_id, stream_name: "Reporting")

            expect { command.call(event_id: event.event_id) }
              .to output(/Orders/).to_stdout
          end

          it "lists all linked streams" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "Orders")
            event_store.link(event.event_id, stream_name: "Reporting")

            expect { command.call(event_id: event.event_id) }
              .to output(/2 stream\(s\)/).to_stdout
          end

          it "excludes global stream" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "Orders")

            expect { command.call(event_id: event.event_id) }
              .to output(/1 stream\(s\)/).to_stdout
          end

          it "prints error for unknown event id" do
            unknown_id = SecureRandom.uuid

            expect {
              begin
                command.call(event_id: unknown_id)
              rescue SystemExit
              end
            }.to output(/Event not found: #{unknown_id}/).to_stderr
          end
        end
      end
    end
  end
end
