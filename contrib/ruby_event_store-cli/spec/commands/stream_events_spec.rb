# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/stream_events"

module RubyEventStore
  module CLI
    module Commands
      class OtherEvent < RubyEventStore::Event; end

      RSpec.describe StreamEvents do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { StreamEvents.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "reads events from given stream" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")

            expect {
              begin
                command.call(stream_name: "test-stream", limit: 50, format: "table")
              rescue SystemExit
              end
            }.to output(/RubyEventStore::Event/).to_stdout
          end

          it "respects limit" do
            5.times { event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream") }

            expect {
              begin
                command.call(stream_name: "test-stream", limit: 2, format: "table")
              rescue SystemExit
              end
            }.to output(/2 event\(s\)/).to_stdout
          end

          it "outputs json when format is json" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")

            expect {
              begin
                command.call(stream_name: "test-stream", limit: 50, format: "json")
              rescue SystemExit
              end
            }.to output(/event_id/).to_stdout
          end

          it "prints message when stream is empty" do
            expect {
              begin
                command.call(stream_name: "empty-stream", limit: 50, format: "table")
              rescue SystemExit
              end
            }.to output(/no events/).to_stdout
          end

          it "prints friendly error for unknown event type" do
            expect {
              begin
                command.call(stream_name: "test-stream", limit: 50, format: "table", type: "NonExistent")
              rescue SystemExit
              end
            }.to output(/Unknown event type: NonExistent/).to_stderr
          end

          it "filters by event type" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")
            event_store.publish(OtherEvent.new, stream_name: "test-stream")

            expect {
              begin
                command.call(stream_name: "test-stream", limit: 50, format: "table", type: "RubyEventStore::CLI::Commands::OtherEvent")
              rescue SystemExit
              end
            }.to output(/1 event\(s\)/).to_stdout
          end

          it "filters by --after timestamp excluding past events" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")
            future = (Time.now + 3600).iso8601(3)

            expect {
              begin
                command.call(stream_name: "test-stream", limit: 50, format: "table", after: future)
              rescue SystemExit
              end
            }.to output(/no events/).to_stdout
          end

          it "filters by --before timestamp excluding future events" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")
            past = (Time.now - 3600).iso8601(3)

            expect {
              begin
                command.call(stream_name: "test-stream", limit: 50, format: "table", before: past)
              rescue SystemExit
              end
            }.to output(/no events/).to_stdout
          end

          it "starts from given event id" do
            e1 = RubyEventStore::Event.new
            e2 = RubyEventStore::Event.new
            e3 = RubyEventStore::Event.new
            event_store.publish([e1, e2, e3], stream_name: "test-stream")

            expect {
              begin
                command.call(stream_name: "test-stream", limit: 50, format: "table", from: e1.event_id)
              rescue SystemExit
              end
            }.to output(/2 event\(s\)/).to_stdout
          end
        end
      end
    end
  end
end
