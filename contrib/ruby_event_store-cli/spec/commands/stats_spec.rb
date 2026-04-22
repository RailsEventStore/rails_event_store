# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/stats"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe Stats do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { Stats.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "shows total event count" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "orders")
            event_store.publish(RubyEventStore::Event.new, stream_name: "payments")

            expect { command.call }
              .to output(/Events:\s+2/).to_stdout
          end

          it "shows zero when no events" do
            expect { command.call }
              .to output(/Events:\s+0/).to_stdout
          end

          it "shows count for a specific stream" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "orders")
            event_store.publish(RubyEventStore::Event.new, stream_name: "orders")
            event_store.publish(RubyEventStore::Event.new, stream_name: "payments")

            expect { command.call(stream: "orders") }
              .to output(/Events:\s+2/).to_stdout
          end

          it "shows stream name when --stream given" do
            expect { command.call(stream: "orders") }
              .to output(/Stream:\s+orders/).to_stdout
          end

          it "does not show stream name for global stats" do
            expect { command.call }
              .not_to output(/Stream/).to_stdout
          end
        end
      end
    end
  end
end
