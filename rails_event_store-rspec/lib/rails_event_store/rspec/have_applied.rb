# frozen_string_literal: true

module RailsEventStore
  module RSpec
    class HaveApplied
      def initialize(mandatory_expected, *optional_expected, differ:, phraser:)
        @expected  = [mandatory_expected, *optional_expected]
        @matcher   = ::RSpec::Matchers::BuiltIn::Include.new(*expected)
        @differ    = differ
        @phraser   = phraser
      end

      def matches?(aggregate_root)
        @events = aggregate_root.unpublished_events.to_a
        matcher.matches?(events) && matches_count?
      end

      def exactly(count)
        @count = count
        self
      end

      def times
        self
      end
      alias :time :times

      def once
        exactly(1)
      end

      def strict
        @matcher = ::RSpec::Matchers::BuiltIn::Match.new(expected)
        self
      end

      def failure_message
        "expected #{expected} to be applied, diff:" +
          differ.diff_as_string(expected.to_s, events.to_s)
      end

      def failure_message_when_negated
        "expected #{expected} not to be applied, diff:" +
            differ.diff_as_string(expected.inspect, events.inspect)
      end

      def description
        "have applied events that have to (#{phraser.(expected)})"
      end

      private

      def matches_count?
        return true unless count
        raise NotSupported if expected.size > 1

        expected.all? do |event_or_matcher|
          events.select { |e| event_or_matcher === e }.size.equal?(count)
        end
      end

      attr_reader :differ, :phraser, :expected, :events, :count, :matcher
    end
  end
end

