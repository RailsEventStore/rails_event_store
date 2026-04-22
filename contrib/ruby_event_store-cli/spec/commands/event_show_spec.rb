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
          it "shows event details" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "test-stream")

            expect { command.call(event_id: event.event_id) }
              .to output(/Event ID:.*#{event.event_id}/).to_stdout
          end

          it "shows event type" do
            event = RubyEventStore::Event.new
            event_store.publish(event, stream_name: "test-stream")

            expect { command.call(event_id: event.event_id) }
              .to output(/Type:.*RubyEventStore::Event/).to_stdout
          end

          it "shows event data as JSON" do
            event = RubyEventStore::Event.new(data: { order_id: "123" })
            event_store.publish(event, stream_name: "test-stream")

            expect { command.call(event_id: event.event_id) }
              .to output(/order_id.*123/).to_stdout
          end

          it "shows event metadata as JSON" do
            event = RubyEventStore::Event.new(metadata: { remote_ip: "1.2.3.4" })
            event_store.publish(event, stream_name: "test-stream")

            expect { command.call(event_id: event.event_id) }
              .to output(/remote_ip.*1\.2\.3\.4/).to_stdout
          end

          it "exits with error for unknown event id" do
            expect {
              begin
                command.call(event_id: "00000000-0000-0000-0000-000000000000")
              rescue SystemExit
              end
            }.to output(/Event not found/).to_stderr
          end
        end
      end
    end
  end
end
