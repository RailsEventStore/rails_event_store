# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/search"

module RubyEventStore
  module CLI
    module Commands
      class SearchTestEvent < RubyEventStore::Event; end

      RSpec.describe Search do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { Search.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "searches all events when no filters given" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "orders")

            expect { command.call(limit: 50, format: "table") }
              .to output(/1 event\(s\)/).to_stdout
          end

          it "filters by event type" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "orders")
            event_store.publish(SearchTestEvent.new, stream_name: "orders")

            expect { command.call(limit: 50, format: "table", type: "RubyEventStore::CLI::Commands::SearchTestEvent") }
              .to output(/1 event\(s\)/).to_stdout
          end

          it "filters by stream" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "orders")
            event_store.publish(RubyEventStore::Event.new, stream_name: "payments")

            expect { command.call(limit: 50, format: "table", stream: "orders") }
              .to output(/1 event\(s\)/).to_stdout
          end

          it "filters by --after timestamp" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "orders")
            future = (Time.now + 3600).iso8601(3)

            expect { command.call(limit: 50, format: "table", after: future) }
              .to output(/no events/).to_stdout
          end

          it "filters by --before timestamp" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "orders")
            past = (Time.now - 3600).iso8601(3)

            expect { command.call(limit: 50, format: "table", before: past) }
              .to output(/no events/).to_stdout
          end

          it "outputs json when format is json" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "orders")

            expect { command.call(limit: 50, format: "json") }
              .to output(/event_id/).to_stdout
          end

          it "respects limit" do
            3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "orders") }

            expect { command.call(limit: 2, format: "table") }
              .to output(/2 event\(s\)/).to_stdout
          end
        end
      end
    end
  end
end
