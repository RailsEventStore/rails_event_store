# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/event_streams"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe EventStreams do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { EventStreams.new }

        before { stub_const("RubyEventStore::CLI::EVENT_STORE", event_store) }

        describe "#call" do
          it "lists streams containing the event" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "orders")
            event_store.link(event.event_id, stream_name: "reporting")

            expect { command.call(event_id: event.event_id) }
              .to output(/orders/).to_stdout
          end

          it "lists all streams the event was linked to" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "orders")
            event_store.link(event.event_id, stream_name: "reporting")

            output = capture_stdout { command.call(event_id: event.event_id) }
            expect(output).to include("orders")
            expect(output).to include("reporting")
          end

          it "prints message when event is not found" do
            expect { command.call(event_id: "00000000-0000-0000-0000-000000000000") }
              .to output(/no streams/).to_stdout
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
