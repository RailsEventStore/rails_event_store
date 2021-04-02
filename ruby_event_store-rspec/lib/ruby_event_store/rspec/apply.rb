# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class Apply
      def initialize(*expected, failure_message_formatter: RSpec.default_formatter.apply)
        @expected = ExpectedCollection.new(expected)
        @failure_message_formatter = failure_message_formatter.new
      end

      def in(aggregate)
        @aggregate = aggregate
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
        raise_aggregate_not_set unless @aggregate
        before = @aggregate.unpublished_events.to_a
        event_proc.call
        @applied_events = @aggregate.unpublished_events.to_a - before
        if match_events?
          MatchEvents.new.call(expected, applied_events)
        else
          !applied_events.empty?
        end
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

      def match_events?
        !expected.events.empty?
      end

      def raise_aggregate_not_set
        raise "You have to set the aggregate instance with `in`, e.g. `expect { ... }.to apply(an_event(MyEvent)).in(aggregate)`"
      end

      attr_reader :expected, :applied_events, :failure_message_formatter
    end
  end
end
