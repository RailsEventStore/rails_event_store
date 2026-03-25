# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/streams_list"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe StreamsList do
        include_context "with AR database"
        let(:event_store) { ar_event_store }
        let(:command) { StreamsList.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "lists all streams" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "Orders")
            event_store.publish(RubyEventStore::Event.new, stream_name: "Users")

            expect {
              begin
                command.call
              rescue SystemExit
              end
            }.to output(/Orders.*Users/m).to_stdout
          end

          it "prints count" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "Orders")
            event_store.publish(RubyEventStore::Event.new, stream_name: "Users")

            expect {
              begin
                command.call
              rescue SystemExit
              end
            }.to output(/2 stream\(s\)/).to_stdout
          end

          it "filters by prefix" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "User-1")
            event_store.publish(RubyEventStore::Event.new, stream_name: "User-2")
            event_store.publish(RubyEventStore::Event.new, stream_name: "Orders")

            expect {
              begin
                command.call(prefix: "User")
              rescue SystemExit
              end
            }.to output(/User-1.*User-2/m).to_stdout
          end

          it "does not include non-matching streams when filtering" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "User-1")
            event_store.publish(RubyEventStore::Event.new, stream_name: "Orders")

            expect {
              begin
                command.call(prefix: "User")
              rescue SystemExit
              end
            }.not_to output(/Orders/).to_stdout
          end

          it "prints filtered count" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "User-1")
            event_store.publish(RubyEventStore::Event.new, stream_name: "User-2")
            event_store.publish(RubyEventStore::Event.new, stream_name: "Orders")

            expect {
              begin
                command.call(prefix: "User")
              rescue SystemExit
              end
            }.to output(/2 stream\(s\)/).to_stdout
          end

          it "prints message when no streams" do
            expect {
              begin
                command.call
              rescue SystemExit
              end
            }.to output(/no streams/).to_stdout
          end
        end
      end
    end
  end
end
