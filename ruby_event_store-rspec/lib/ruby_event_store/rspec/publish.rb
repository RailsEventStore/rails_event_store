# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class Publish
      def initialize(*expected, failure_message_formatter: RSpec.default_formatter.publish)
        @expected = ExpectedCollection.new(expected)
        @failure_message_formatter = failure_message_formatter.new
        @fetch_events = FetchEvents.new
      end

      def in(event_store)
        fetch_events.in(event_store)
        self
      end

      def in_stream(stream)
        fetch_events.stream(stream)
        self
      end

      def exactly(count)
        expected.exactly(count)
        self
      end

      def once
        expected.once
        self
      end

      def times
        self
      end
      alias :time :times

      def strict
        expected.strict
        self
      end

      def matches?(event_proc)
        fetch_events.from_last
        event_proc.call
        @published_events = fetch_events.call.to_a
        MatchEvents.new.call(expected, published_events)
      rescue FetchEvents::MissingEventStore
        raise "You have to set the event store instance with `in`, e.g. `expect { ... }.to publish(an_event(MyEvent)).in(event_store)`"
      end

      def failure_message
        failure_message_formatter.failure_message(expected, published_events, fetch_events.stream_name)
      end

      def failure_message_when_negated
        failure_message_formatter.failure_message_when_negated(expected, published_events, fetch_events.stream_name)
      end

      def description
        "publish events"
      end

      def supports_block_expectations?
        true
      end

      private

      attr_reader :fetch_events, :expected, :failure_message_formatter, :published_events
    end
  end
end
