# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp/read_events"

module RubyEventStore
  module MCP
    ::RSpec.describe ReadEvents do
      let(:event_store) { RubyEventStore::Client.new }

      class TestEvent < RubyEventStore::Event; end

      describe ".of" do
        it "returns all events with no options" do
          event_store.publish(TestEvent.new, stream_name: "test")
          result = ReadEvents.of(event_store.read)
          expect(result).not_to be_empty
        end

        it "returns an array" do
          result = ReadEvents.of(event_store.read)
          expect(result).to be_an(Array)
        end

        it "returns event objects" do
          event_store.publish(TestEvent.new, stream_name: "test")
          result = ReadEvents.of(event_store.read)
          expect(result.first).to respond_to(:event_type)
        end

        it "applies limit when given" do
          3.times { event_store.publish(TestEvent.new, stream_name: "test") }
          result = ReadEvents.of(event_store.read, limit: 2)
          expect(result.size).to eq(2)
        end

        it "returns all events when no limit given" do
          3.times { event_store.publish(TestEvent.new, stream_name: "test") }
          result = ReadEvents.of(event_store.read)
          expect(result.size).to eq(3)
        end

        it "filters by type" do
          event_store.publish(TestEvent.new, stream_name: "test")
          event_store.publish(RubyEventStore::Event.new, stream_name: "test")
          result = ReadEvents.of(event_store.read, type: "RubyEventStore::MCP::TestEvent")
          expect(result.map(&:event_type).uniq).to eq(["RubyEventStore::MCP::TestEvent"])
        end

        it "filters by after timestamp excluding old events" do
          event_store.publish(TestEvent.new, stream_name: "test")
          result = ReadEvents.of(event_store.read, after: (Time.now + 3600).iso8601)
          expect(result).to be_empty
        end

        it "filters by after timestamp including newer events" do
          event_store.publish(TestEvent.new, stream_name: "test")
          result = ReadEvents.of(event_store.read, after: (Time.now - 3600).iso8601)
          expect(result).not_to be_empty
        end

        it "filters by before timestamp excluding newer events" do
          event_store.publish(TestEvent.new, stream_name: "test")
          result = ReadEvents.of(event_store.read, before: (Time.now - 3600).iso8601)
          expect(result).to be_empty
        end

        it "filters by before timestamp including older events" do
          event_store.publish(TestEvent.new, stream_name: "test")
          result = ReadEvents.of(event_store.read, before: (Time.now + 3600).iso8601)
          expect(result).not_to be_empty
        end

        it "filters by from event id excluding the referenced event" do
          e1 = TestEvent.new
          e2 = TestEvent.new
          event_store.publish(e1, stream_name: "test")
          event_store.publish(e2, stream_name: "test")
          result = ReadEvents.of(event_store.read.stream("test"), from: e1.event_id)
          event_ids = result.map(&:event_id)
          expect(event_ids).to include(e2.event_id)
          expect(event_ids).not_to include(e1.event_id)
        end

        it "returns all events when from is not given" do
          e1 = TestEvent.new
          e2 = TestEvent.new
          event_store.publish(e1, stream_name: "test")
          event_store.publish(e2, stream_name: "test")
          result = ReadEvents.of(event_store.read.stream("test"))
          event_ids = result.map(&:event_id)
          expect(event_ids).to include(e1.event_id)
          expect(event_ids).to include(e2.event_id)
        end

        it "raises for unknown event type" do
          expect { ReadEvents.of(event_store.read, type: "NonExistentClass") }
            .to raise_error(RuntimeError, /NonExistentClass/)
        end
      end
    end
  end
end
