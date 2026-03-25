# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/event_show"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe EventShow do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { EventShow.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "shows event id" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "test-stream")

            expect {
              begin
                command.call(event_id: event.event_id)
              rescue SystemExit
              end
            }.to output(/Event ID:.*#{event.event_id}/m).to_stdout
          end

          it "shows event type" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "test-stream")

            expect {
              begin
                command.call(event_id: event.event_id)
              rescue SystemExit
              end
            }.to output(/Type:.*RubyEventStore::Event/m).to_stdout
          end

          it "shows timestamp" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "test-stream")

            expect {
              begin
                command.call(event_id: event.event_id)
              rescue SystemExit
              end
            }.to output(/Timestamp:.*#{event.timestamp.iso8601(3)}/m).to_stdout
          end

          it "shows event data as JSON" do
            event = RubyEventStore::Event.new(data: { order_id: "123" })
            event_store.publish(event, stream_name: "test-stream")

            expect {
              begin
                command.call(event_id: event.event_id)
              rescue SystemExit
              end
            }.to output(/order_id/).to_stdout
          end

          it "shows event metadata as JSON" do
            event = RubyEventStore::Event.new(metadata: { correlation_id: "abc" })
            event_store.publish(event, stream_name: "test-stream")

            expect {
              begin
                command.call(event_id: event.event_id)
              rescue SystemExit
              end
            }.to output(/correlation_id/).to_stdout
          end

          it "does not show valid_at when same as timestamp" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "test-stream")

            expect {
              begin
                command.call(event_id: event.event_id)
              rescue SystemExit
              end
            }.not_to output(/Valid at:/).to_stdout
          end

          it "prints friendly error for unknown event id" do
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
