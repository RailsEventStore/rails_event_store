# frozen_string_literal: true

require "spec_helper"

module RailsEventStore
  module HotwireBrowser
    ::RSpec.describe GetEventsFromStream do
      let(:event_store) { RubyEventStore::Client.new }

      def reader(stream_name: "dummy", page: {})
        GetEventsFromStream.new(event_store: event_store, stream_name: stream_name, page: page)
      end

      def publish(count, stream: "dummy")
        Array.new(count) do
          event = DummyEvent.new
          event_store.publish(event, stream_name: stream)
          event
        end
      end

      specify "empty stream has no events and no pagination" do
        expect(reader.events).to eq([])
        expect(reader.pagination).to eq({})
      end

      specify "count defaults to PAGE_SIZE" do
        expect(reader.count).to eq(20)
      end

      specify "count is read from the page params" do
        expect(reader(page: { "count" => "5" }).count).to eq(5)
      end

      specify "a nil page behaves like an empty one" do
        expect(reader(page: nil).count).to eq(20)
      end

      specify %("head" position reads from the newest, like no position) do
        publish(25)
        expect(reader(page: { "position" => "head" }).events.map(&:event_id)).to eq(reader.events.map(&:event_id))
      end

      specify "reads the newest events first, capped at count" do
        events = publish(25)
        result = reader.events
        expect(result.size).to eq(20)
        expect(result.first.event_id).to eq(events[24].event_id)
        expect(result.last.event_id).to eq(events[5].event_id)
      end

      specify "a stream that fits in one page has no pagination" do
        publish(20)
        expect(reader.pagination).to eq({})
      end

      specify "offers next/last when older events remain" do
        events = publish(25)
        expect(reader.pagination).to eq(
          next: { position: events[5].event_id, direction: :backward },
          last: { position: :head, direction: :forward },
        )
      end

      specify "offers prev/first when paginated past the newest events" do
        events = publish(25)
        page = { "position" => events[5].event_id, "direction" => "backward" }
        expect(reader(page: page).pagination).to eq(
          prev: { position: events[4].event_id, direction: :forward },
          first: { position: :head, direction: :backward },
        )
      end

      specify "reading backward from a position returns older events, newest first" do
        events = publish(25)
        page = { "position" => events[5].event_id, "direction" => "backward" }
        expect(reader(page: page).events.map(&:event_id)).to eq(events[0..4].reverse.map(&:event_id))
      end

      specify "reading forward from a position returns newer events, newest first" do
        events = publish(25)
        page = { "position" => events[5].event_id, "direction" => "forward", "count" => "3" }
        expect(reader(page: page).events.map(&:event_id)).to eq([events[8], events[7], events[6]].map(&:event_id))
      end

      specify "a named stream reads only its own events" do
        mine = DummyEvent.new
        other = DummyEvent.new
        event_store.publish(mine, stream_name: "dummy")
        event_store.publish(other, stream_name: "other")

        expect(reader(stream_name: "dummy").events.map(&:event_id)).to eq([mine.event_id])
      end

      specify "the global stream reads across all streams" do
        first = DummyEvent.new
        second = DummyEvent.new
        event_store.publish(first, stream_name: "one")
        event_store.publish(second, stream_name: "two")
        expect(reader(stream_name: "all").events.map(&:event_id)).to eq([second.event_id, first.event_id])
      end
    end
  end
end
