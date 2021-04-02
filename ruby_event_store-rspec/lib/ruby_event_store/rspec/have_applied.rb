# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class HaveApplied
      def initialize(*expected, differ:, phraser:, failure_message_formatter: RSpec.default_formatter.have_applied)
        @expected  = ExpectedCollection.new(expected)
        @failure_message_formatter = failure_message_formatter.new(differ)
        @phraser   = phraser
      end

      def matches?(aggregate_root)
        @events = aggregate_root.unpublished_events.to_a
        if match_events?
          MatchEvents.new.call(expected, events)
        else
          !events.to_a.empty?
        end
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

      def match_events?
        !expected.events.empty?
      end

      attr_reader :phraser, :expected, :events, :failure_message_formatter
    end
  end
end
