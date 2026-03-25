# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/stream_show"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe StreamShow do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { StreamShow.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "shows stream name" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")

            expect {
              begin
                command.call(stream_name: "test-stream")
              rescue SystemExit
              end
            }.to output(/Stream:.*test-stream/m).to_stdout
          end

          it "shows event count" do
            3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream") }

            expect {
              begin
                command.call(stream_name: "test-stream")
              rescue SystemExit
              end
            }.to output(/Events:.*3/m).to_stdout
          end

          it "shows version" do
            3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream") }

            expect {
              begin
                command.call(stream_name: "test-stream")
              rescue SystemExit
              end
            }.to output(/Version:.*2/m).to_stdout
          end

          it "shows first event type" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")

            expect {
              begin
                command.call(stream_name: "test-stream")
              rescue SystemExit
              end
            }.to output(/First:.*RubyEventStore::Event/m).to_stdout
          end

          it "shows last event type" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")

            expect {
              begin
                command.call(stream_name: "test-stream")
              rescue SystemExit
              end
            }.to output(/Last:.*RubyEventStore::Event/m).to_stdout
          end

          it "shows zero count for empty stream" do
            expect {
              begin
                command.call(stream_name: "empty-stream")
              rescue SystemExit
              end
            }.to output(/Events:.*0/m).to_stdout
          end

          it "does not show version for empty stream" do
            expect {
              begin
                command.call(stream_name: "empty-stream")
              rescue SystemExit
              end
            }.not_to output(/Version:/).to_stdout
          end
        end
      end
    end
  end
end
