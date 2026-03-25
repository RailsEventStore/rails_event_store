# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/link"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe Link do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { Link.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "links event to the given stream" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "source-stream")

            begin
              command.call(event_id: event.event_id, stream: "target-stream")
            rescue SystemExit
            end

            events = event_store.read.stream("target-stream").to_a
            expect(events.map(&:event_id)).to include(event.event_id)
          end

          it "prints confirmation" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "source-stream")

            expect {
              begin
                command.call(event_id: event.event_id, stream: "target-stream")
              rescue SystemExit
              end
            }.to output(/Linked #{event.event_id} to target-stream/).to_stdout
          end

          it "prints error for unknown event id" do
            unknown_id = SecureRandom.uuid

            expect {
              begin
                command.call(event_id: unknown_id, stream: "target-stream")
              rescue SystemExit
              end
            }.to output(/#{unknown_id}/).to_stderr
          end
        end
      end
    end
  end
end
