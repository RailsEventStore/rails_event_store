# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class HaveApplied
      def initialize(mandatory_expected, *optional_expected, differ:, phraser:, failure_message_formatter: RSpec.default_formatter.have_applied)
        @expected  = ExpectedCollection.new([mandatory_expected, *optional_expected])
        @failure_message_formatter = failure_message_formatter.new(differ)
        @phraser   = phraser
      end

      def matches?(aggregate_root)
        @events = aggregate_root.unpublished_events.to_a
        MatchEvents.new.call(expected, events)
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

      def strict
        expected.strict
        self
      end

      def failure_message
        failure_message_formatter.failure_message(expected, events)
      end

      def failure_message_when_negated
        failure_message_formatter.failure_message_when_negated(expected, events)
      end

      def description
        "have applied events that have to (#{phraser.(expected.events)})"
      end

      private

      attr_reader :phraser, :expected, :events, :failure_message_formatter
    end
  end
end
