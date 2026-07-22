# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Browser
    ::RSpec.describe GetEventsFromStreams do
      let(:event_store) { RubyEventStore::Client.new }
      let(:base_time) { Time.utc(2024, 1, 1, 12, 0, 0) }

      def reader(stream_names:, cursor: nil, sort: nil, count: 20)
        GetEventsFromStreams.new(
          event_store: event_store,
          stream_names: stream_names,
          cursor: cursor,
          sort: sort,
          count: count,
        )
      end

      def next_page(previous, stream_names:, count:, sort: nil)
        reader(stream_names: stream_names, cursor: previous.next_cursor, sort: sort, count: count)
      end

      def publish(stream:, at: nil, valid_at: nil)
        event = DummyEvent.new
        if at
          event.metadata[:timestamp] = at
          event.metadata[:valid_at] = valid_at || at
        end
        event_store.publish(event, stream_name: stream)
        event
      end

      specify "merges events from multiple streams, newest first, tagged with their owning stream" do
        a1 = publish(stream: "a", at: base_time + 1)
        b1 = publish(stream: "b", at: base_time + 2)
        a2 = publish(stream: "a", at: base_time + 3)

        result = reader(stream_names: %w[a b]).events.map { |names, event| [names, event.event_id] }
        expect(result).to eq([[["a"], a2.event_id], [["b"], b1.event_id], [["a"], a1.event_id]])
      end

      specify "orders by event time, not by position in the stream" do
        newer = publish(stream: "a", at: base_time + 2)
        older = publish(stream: "a", at: base_time + 1)

        result = reader(stream_names: %w[a]).events.map { |_, event| event.event_id }
        expect(result).to eq([newer.event_id, older.event_id])
      end

      specify "a single stream page is capped at count" do
        6.times { |i| publish(stream: "a", at: base_time + i) }
        expect(reader(stream_names: %w[a], count: 3).events.size).to eq(3)
      end

      specify "a page emits everything above the completeness horizon, not just count events" do
        a1 = publish(stream: "a", at: base_time + 1)
        b2 = publish(stream: "b", at: base_time + 2)
        a3 = publish(stream: "a", at: base_time + 3)
        b4 = publish(stream: "b", at: base_time + 4)

        page = reader(stream_names: %w[a b], count: 2)
        expect(page.events.map { |_, event| event.event_id }).to eq([b4, a3, b2].map(&:event_id))
        expect(page.more?).to eq(true)

        rest = next_page(page, stream_names: %w[a b], count: 2)
        expect(rest.events.map { |_, event| event.event_id }).to eq([a1.event_id])
        expect(rest.more?).to eq(false)
      end

      specify "more? is true when the page is full" do
        3.times { |i| publish(stream: "a", at: base_time + i) }
        expect(reader(stream_names: %w[a], count: 3).more?).to eq(true)
      end

      specify "streams read to exhaustion merge into a single page" do
        2.times { |i| publish(stream: "a", at: base_time + i) }
        2.times { |i| publish(stream: "b", at: base_time + 10 + i) }

        page = reader(stream_names: %w[a b], count: 3)
        expect(page.events.size).to eq(4)
        expect(page.more?).to eq(false)
      end

      specify "more? is false once every stream is exhausted" do
        3.times { |i| publish(stream: "a", at: base_time + i) }
        expect(reader(stream_names: %w[a], count: 20).more?).to eq(false)
      end

      specify "next_cursor is the last returned event's timestamp" do
        publish(stream: "a", at: base_time + 1)
        a2 = publish(stream: "a", at: base_time + 2)
        a3 = publish(stream: "a", at: base_time + 3)

        page = reader(stream_names: %w[a], count: 2)
        expect(page.events.map { |_, event| event.event_id }).to eq([a3.event_id, a2.event_id])
        expect(page.next_cursor).to eq((base_time + 2).iso8601(TIMESTAMP_PRECISION))
      end

      specify "continues below the cursor timestamp" do
        a1 = publish(stream: "a", at: base_time + 1)
        a2 = publish(stream: "a", at: base_time + 2)
        a3 = publish(stream: "a", at: base_time + 3)

        page = reader(stream_names: %w[a], count: 2)
        rest = next_page(page, stream_names: %w[a], count: 2)
        expect(page.events.map { |_, event| event.event_id }).to eq([a3.event_id, a2.event_id])
        expect(rest.events.map { |_, event| event.event_id }).to eq([a1.event_id])
        expect(rest.more?).to eq(false)
      end

      specify "does not skip an event from another stream sharing the boundary timestamp" do
        old = publish(stream: "a", at: base_time + 1)
        tied_a = publish(stream: "a", at: base_time + 2)
        tied_b = publish(stream: "b", at: base_time + 2)
        newest = publish(stream: "b", at: base_time + 3)

        page = reader(stream_names: %w[a b], count: 2)
        rest = next_page(page, stream_names: %w[a b], count: 2)

        expect(page.events.map { |_, event| event.event_id }).to match_array(
          [newest, tied_a, tied_b].map(&:event_id),
        )
        expect(rest.events.map { |_, event| event.event_id }).to eq([old.event_id])
      end

      specify "a page runs to the end of its last timestamp instead of splitting the group" do
        published = 7.times.map { publish(stream: "a", at: base_time) }

        page = reader(stream_names: %w[a], count: 3)
        expect(page.events.map { |_, event| event.event_id }).to match_array(published.map(&:event_id))

        rest = next_page(page, stream_names: %w[a], count: 3)
        expect(rest.events).to eq([])
        expect(rest.more?).to eq(false)
      end

      specify "pages through mixed unique and tied timestamps without drops or duplicates" do
        published = 3.times.map { |i| publish(stream: "a", at: base_time + i) }
        published += 4.times.map { publish(stream: "a", at: base_time + 10) }
        published += 2.times.map { |i| publish(stream: "b", at: base_time + 20 + i) }

        pages = [reader(stream_names: %w[a b], count: 3)]
        pages << next_page(pages.last, stream_names: %w[a b], count: 3) while pages.last.more?

        emitted = pages.flat_map { |page| page.events.map { |_, event| event.event_id } }
        expect(emitted).to match_array(published.map(&:event_id))
      end

      specify "an event linked into more than one compared stream is one row shown in both columns, not duplicated" do
        a1 = publish(stream: "a", at: base_time)
        event_store.link([a1.event_id], stream_name: "b")

        result = reader(stream_names: %w[a b]).events
        expect(result.map { |_, event| event.event_id }).to eq([a1.event_id])
        expect(result.first.first).to match_array(%w[a b])
      end

      specify "does not repeat a stream in the columns of an event fetched twice" do
        3.times { publish(stream: "a", at: base_time) }

        result = reader(stream_names: %w[a], count: 3).events
        expect(result.map(&:first)).to eq([["a"], ["a"], ["a"]])
      end

      specify "sorts by validity time when sort is as_of" do
        e1 = publish(stream: "a", at: base_time + 3, valid_at: base_time + 11)
        e2 = publish(stream: "b", at: base_time + 2, valid_at: base_time + 12)
        e3 = publish(stream: "a", at: base_time + 1, valid_at: base_time + 13)

        by_append = reader(stream_names: %w[a b]).events.map { |_, event| event.event_id }
        by_validity = reader(stream_names: %w[a b], sort: "as_of").events.map { |_, event| event.event_id }
        expect(by_append).to eq([e1.event_id, e2.event_id, e3.event_id])
        expect(by_validity).to eq([e3.event_id, e2.event_id, e1.event_id])
      end

      specify "as_of cursor pages along the validity axis" do
        e1 = publish(stream: "a", at: base_time + 3, valid_at: base_time + 11)
        e2 = publish(stream: "a", at: base_time + 2, valid_at: base_time + 12)
        e3 = publish(stream: "a", at: base_time + 1, valid_at: base_time + 13)

        page = reader(stream_names: %w[a], sort: "as_of", count: 2)
        expect(page.events.map { |_, event| event.event_id }).to eq([e3.event_id, e2.event_id])
        expect(page.next_cursor).to eq((base_time + 12).iso8601(TIMESTAMP_PRECISION))

        rest = next_page(page, stream_names: %w[a], sort: "as_of", count: 2)
        expect(rest.events.map { |_, event| event.event_id }).to eq([e1.event_id])
        expect(rest.more?).to eq(false)
      end

      specify "as_of pages run to the end of their last validity time instead of splitting the group" do
        published = 4.times.map { |i| publish(stream: "a", at: base_time + i, valid_at: base_time + 10) }

        page = reader(stream_names: %w[a], sort: "as_of", count: 3)
        expect(page.events.map { |_, event| event.event_id }).to match_array(published.map(&:event_id))
      end

      specify "the global stream alias reads all events, not a stream named all" do
        a1 = publish(stream: "orders", at: base_time + 1)
        a2 = publish(stream: "shipments", at: base_time + 2)

        result = reader(stream_names: %w[all orders]).events.map { |names, event| [names, event.event_id] }
        expect(result).to eq([[%w[all], a2.event_id], [%w[all orders], a1.event_id]])
      end

      specify "reads each stream once per page" do
        publish(stream: "a", at: base_time)
        publish(stream: "b", at: base_time + 1)

        allow(event_store).to receive(:read).and_call_original
        reader(stream_names: %w[a b c]).events

        expect(event_store).to have_received(:read).exactly(3).times
      end
    end
  end
end
