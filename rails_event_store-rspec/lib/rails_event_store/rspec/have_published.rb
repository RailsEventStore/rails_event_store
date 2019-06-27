# frozen_string_literal: true

module RailsEventStore
  module RSpec
    class HavePublished
      def initialize(mandatory_expected, *optional_expected, differ:, phraser:)
        @expected  = [mandatory_expected, *optional_expected]
        @matcher   = ::RSpec::Matchers::BuiltIn::Include.new(*expected)
        @differ    = differ
        @phraser   = phraser
      end

      def matches?(event_store)
        @events = event_store.read
        @events = events.stream(stream_name) if stream_name
        @events = events.from(start)         if start
        @events = events.each
        @matcher.matches?(events) && matches_count?
      end

      def exactly(count)
        @count = count
        self
      end

      def in_stream(stream_name)
        @stream_name = stream_name
        self
      end

      def times
        self
      end
      alias :time :times

      def from(event_id)
        @start = event_id
        self
      end

      def once
        exactly(1)
      end

      def failure_message
        "expected #{expected} to be published, diff:" +
            differ.diff_as_string(expected.to_s, events.to_a.to_s)
      end

      def failure_message_when_negated
        "expected #{expected} not to be published, diff:" +
            differ.diff_as_string(expected.to_s, events.to_a.to_s)
      end

      def description
        "have published events that have to (#{phraser.(expected)})"
      end

      def strict
        @matcher = ::RSpec::Matchers::BuiltIn::Match.new(expected)
        self
      end

      private

      def matches_count?
        return true unless count
        raise NotSupported if expected.size > 1

        expected.all? do |event_or_matcher|
          events.select { |e| event_or_matcher === e }.size.equal?(count)
        end
      end

      attr_reader :differ, :phraser, :stream_name, :expected, :count, :events, :start
    end
  end
end
