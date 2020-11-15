# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class HavePublished
      class CrudeFailureMessageFormatter
        def initialize(differ)
          @differ = differ
        end

        def failure_message(_matcher, expected, events, _expected_count)
          "expected #{expected} to be published, diff:" +
            differ.diff_as_string(expected.to_s, events.to_a.to_s)
        end

        def negated_failure_message(_matcher, expected, events, _expected_count)
          "expected #{expected} not to be published, diff:" +
            differ.diff_as_string(expected.to_s, events.to_a.to_s)
        end

        private
        attr_reader :differ
      end

      class StepByStepFailureMessageFormatter
        def initialize(differ)
          @differ = differ
        end

        def failure_message(_matcher, expected, events, expected_count)
          expected.each do |expected_event|
            correct_event_count = 0
            events.each do |actual_event|
              if expected_event.matches?(actual_event)
                correct_event_count += 1
              end
            end

            if correct_event_count != expected_count
              return <<~EOS
              expected event #{expected}
              to be published #{expected_count} times
              but was published #{correct_event_count} times
              EOS
            end
          end
        end

        def negated_failure_message(_matcher, expected, events, expected_count)
          "expected #{expected} not to be published, diff:" +
            differ.diff_as_string(expected.to_s, events.to_a.to_s)
        end

        private
        attr_reader :differ
      end

      def initialize(mandatory_expected, *optional_expected, differ:, phraser:, failure_message_formatter: CrudeFailureMessageFormatter)
        @expected  = [mandatory_expected, *optional_expected]
        @matcher   = ::RSpec::Matchers::BuiltIn::Include.new(*expected)
        @differ    = differ
        @phraser   = phraser
        @failure_message_formatter = failure_message_formatter.new(@differ)
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
        failure_message_formatter.failure_message(matcher, expected, events, count)
      end

      def failure_message_when_negated
        failure_message_formatter.negated_failure_message(matcher, expected, events, count)
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
        events.select { |e| expected.first === e }.size.equal?(count)
      end

      attr_reader :differ, :phraser, :stream_name, :expected, :count, :events, :start, :failure_message_formatter, :matcher
    end
  end
end
