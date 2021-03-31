# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class HaveApplied
      def initialize(mandatory_expected, *optional_expected, differ:, phraser:)
        @expected  = ExpectedCollection.new([mandatory_expected, *optional_expected])
        @differ    = differ
        @phraser   = phraser
      end

      def matches?(aggregate_root)
        @events = aggregate_root.unpublished_events.to_a
        MatchEvents.new.call(expected, events)
      end

      def exactly(count)
        @expected.exactly(count)
        self
      end

      def times
        self
      end
      alias :time :times

      def once
        @expected.once
        self
      end

      def strict
        @expected.strict
        self
      end

      def failure_message
        "expected #{expected.events} to be applied, diff:" +
          differ.diff(expected.events.to_s + "\n", events)
      end

      def failure_message_when_negated
        "expected #{expected.events} not to be applied, diff:" +
          differ.diff(expected.events.inspect + "\n", events)
      end

      def description
        "have applied events that have to (#{phraser.(expected.events)})"
      end

      private

      attr_reader :differ, :phraser, :expected, :events
    end
  end
end

