# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class Apply
      def initialize(*expected, failure_message_formatter:)
        @expected = ExpectedCollection.new(expected)
        @failure_message_formatter = failure_message_formatter
        @fetch_events = FetchUnpublishedEvents.new
      end

      def in(aggregate)
        fetch_events.in(aggregate)
        self
      end

      def strict
        expected.strict
        self
      end

      def exactly(count)
        expected.exactly(count)
        self
      end

      def times
        self
      end
      alias :time :times

      def once
        expected.once
        self
      end

      def matches?(event_proc)
        raise_aggregate_not_set unless fetch_events.aggregate?
        before = fetch_events.aggregate.unpublished_events.to_a
        event_proc.call
        @applied_events = fetch_events.aggregate.unpublished_events.to_a - before
        MatchEvents.new.call(expected, applied_events)
      end

      def failure_message
        failure_message_formatter.failure_message(expected, applied_events)
      end

      def failure_message_when_negated
        failure_message_formatter.failure_message_when_negated(expected, applied_events)
      end

      def description
        "apply events"
      end

      def supports_block_expectations?
        true
      end

      private

      def raise_aggregate_not_set
        raise "You have to set the aggregate instance with `in`, e.g. `expect { ... }.to apply(an_event(MyEvent)).in(aggregate)`"
      end

      attr_reader :expected, :applied_events, :failure_message_formatter, :fetch_events
    end
  end
end
