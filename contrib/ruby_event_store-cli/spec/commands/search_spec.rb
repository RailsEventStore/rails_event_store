# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/search"

module RubyEventStore
  module CLI
    module Commands
      class SearchEvent < RubyEventStore::Event; end
      class OtherSearchEvent < RubyEventStore::Event; end

      RSpec.describe Search do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { Search.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "returns all events when no filters given" do
            3.times { event_store.publish(SearchEvent.new, stream_name: "test") }

            expect {
              begin
                command.call
              rescue SystemExit
              end
            }.to output(/3 event\(s\)/).to_stdout
          end

          it "filters by type using global stream" do
            event_store.publish(SearchEvent.new,      stream_name: "test")
            event_store.publish(OtherSearchEvent.new, stream_name: "test")

            expect {
              begin
                command.call(type: "RubyEventStore::CLI::Commands::SearchEvent")
              rescue SystemExit
              end
            }.to output(/1 event\(s\)/).to_stdout
          end

          it "filters by stream" do
            event_store.publish(SearchEvent.new, stream_name: "stream-a")
            event_store.publish(SearchEvent.new, stream_name: "stream-b")

            expect {
              begin
                command.call(stream: "stream-a")
              rescue SystemExit
              end
            }.to output(/1 event\(s\)/).to_stdout
          end

          it "filters by stream and type" do
            event_store.publish(SearchEvent.new,      stream_name: "stream-a")
            event_store.publish(SearchEvent.new,      stream_name: "stream-b")
            event_store.publish(OtherSearchEvent.new, stream_name: "stream-a")

            expect {
              begin
                command.call(stream: "stream-a", type: "RubyEventStore::CLI::Commands::SearchEvent")
              rescue SystemExit
              end
            }.to output(/1 event\(s\)/).to_stdout
          end

          it "filters by --after timestamp" do
            event_store.publish(SearchEvent.new, stream_name: "test")
            future = (Time.now + 3600).iso8601(3)

            expect {
              begin
                command.call(after: future)
              rescue SystemExit
              end
            }.to output(/no events/).to_stdout
          end

          it "filters by --before timestamp" do
            event_store.publish(SearchEvent.new, stream_name: "test")
            past = (Time.now - 3600).iso8601(3)

            expect {
              begin
                command.call(before: past)
              rescue SystemExit
              end
            }.to output(/no events/).to_stdout
          end

          it "respects limit" do
            5.times { event_store.publish(SearchEvent.new, stream_name: "test") }

            expect {
              begin
                command.call(limit: 2)
              rescue SystemExit
              end
            }.to output(/2 event\(s\)/).to_stdout
          end

          it "outputs json when format is json" do
            event_store.publish(SearchEvent.new, stream_name: "test")

            expect {
              begin
                command.call(format: "json")
              rescue SystemExit
              end
            }.to output(/event_id/).to_stdout
          end

          it "prints error for unknown event type" do
            expect {
              begin
                command.call(type: "NonExistentType")
              rescue SystemExit
              end
            }.to output(/Unknown event type: NonExistentType/).to_stderr
          end
        end
      end
    end
  end
end
