# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/stats"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe Stats do
        include_context "with AR database"
        let(:event_store) { ar_event_store }
        let(:command) { Stats.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "shows total event count" do
            3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "test") }

            expect {
              begin
                command.call
              rescue SystemExit
              end
            }.to output(/Total events:.*3/m).to_stdout
          end

          it "shows stream count" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "Orders")
            event_store.publish(RubyEventStore::Event.new, stream_name: "Users")

            expect {
              begin
                command.call
              rescue SystemExit
              end
            }.to output(/Streams:.*2/m).to_stdout
          end

          it "shows top event types" do
            3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "test") }

            expect {
              begin
                command.call
              rescue SystemExit
              end
            }.to output(/RubyEventStore::Event.*3/m).to_stdout
          end

          context "with --stream" do
            it "shows stream name" do
              3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "Orders") }

              expect {
                begin
                  command.call(stream: "Orders")
                rescue SystemExit
                end
              }.to output(/Stream:.*Orders/m).to_stdout
            end

            it "shows stream event count" do
              3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "Orders") }

              expect {
                begin
                  command.call(stream: "Orders")
                rescue SystemExit
                end
              }.to output(/Events:.*3/m).to_stdout
            end

            it "shows version for non-empty stream" do
              3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "Orders") }

              expect {
                begin
                  command.call(stream: "Orders")
                rescue SystemExit
                end
              }.to output(/Version:.*2/m).to_stdout
            end

            it "shows first event type" do
              3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "Orders") }

              expect {
                begin
                  command.call(stream: "Orders")
                rescue SystemExit
                end
              }.to output(/First:.*RubyEventStore::Event/m).to_stdout
            end

            it "shows last event type" do
              3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "Orders") }

              expect {
                begin
                  command.call(stream: "Orders")
                rescue SystemExit
                end
              }.to output(/Last:.*RubyEventStore::Event/m).to_stdout
            end

            it "shows zero count for empty stream" do
              expect {
                begin
                  command.call(stream: "empty")
                rescue SystemExit
                end
              }.to output(/Events:.*0/m).to_stdout
            end

            it "does not show version for empty stream" do
              expect {
                begin
                  command.call(stream: "empty")
                rescue SystemExit
                end
              }.not_to output(/Version:/).to_stdout
            end
          end
        end
      end
    end
  end
end
