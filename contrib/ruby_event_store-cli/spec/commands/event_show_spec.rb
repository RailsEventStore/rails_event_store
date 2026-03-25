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
          it "shows event id, type and timestamp" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "test-stream")

            expect { command.call(event_id: event.event_id) }
              .to output(/#{event.event_id}/).to_stdout
          end

          it "shows event data as JSON" do
            event = RubyEventStore::Event.new(data: { order_id: "123" })
            event_store.publish(event, stream_name: "test-stream")

            expect { command.call(event_id: event.event_id) }
              .to output(/order_id/).to_stdout
          end

          it "shows event metadata as JSON" do
            event = RubyEventStore::Event.new(metadata: { correlation_id: "abc" })
            event_store.publish(event, stream_name: "test-stream")

            expect { command.call(event_id: event.event_id) }
              .to output(/correlation_id/).to_stdout
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
