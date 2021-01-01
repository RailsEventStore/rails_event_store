# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class HavePublished
      class CrudeFailureMessageFormatter
        def initialize(differ)
          @differ = differ
        end

        def failure_message(_matcher, expected, events, _expected_count, _strict)
          "expected #{expected} to be published, diff:" +
            differ.diff_as_string(expected.to_s, events.to_a.to_s)
        end

        def negated_failure_message(_matcher, expected, events, _expected_count, _strict)
          "expected #{expected} not to be published, diff:" +
            differ.diff_as_string(expected.to_s, events.to_a.to_s)
        end

        private
        attr_reader :differ
      end

      class StepByStepFailureMessageFormatter
        def initialize(differ)
          @differ = differ
          @fallback = CrudeFailureMessageFormatter.new(differ)
        end

        def failure_message(_matcher, expected, events, expected_count, strict)
          return fallback.failure_message(_matcher, expected, events, expected_count, strict) if strict
          expected.each do |expected_event|
            correct_event_count = 0
            event_with_correct_type = nil
            events.each do |actual_event|
              if expected_event.matches?(actual_event)
                correct_event_count += 1
              elsif BeEvent::KindMatcher.new(expected_event.expected).matches?(actual_event)
                event_with_correct_type = actual_event
              end
            end

            if expected_count && correct_event_count >= 1 && correct_event_count != expected_count
              return <<~EOS
              expected event #{expected}
              to be published #{expected_count} times
              but was published #{correct_event_count} times
              EOS
            elsif event_with_correct_type
              return <<~EOS
              expected event #{expected}
              to be published, but it was not published

              there is an event of correct type but with incorrect payload:
              #{data_diff(expected_event, event_with_correct_type)}#{metadata_diff(expected_event, event_with_correct_type)}
              EOS
            elsif correct_event_count.zero?
              return <<~EOS
              expected event #{expected}
              to be published, but there is no event with such type
              EOS
            end
          end
        end

        def negated_failure_message(_matcher, expected, events, expected_count, strict)
          return fallback.negated_failure_message(_matcher, expected, events, expected_count, strict) if strict
          "expected #{expected} not to be published, diff:" +
            differ.diff_as_string(expected.to_s, events.to_a.to_s)
        end

        private
        attr_reader :differ, :fallback

        def data_diff(expected_event, event_with_correct_type)
          if expected_event.expected_data.nil?
            ""
          else
            "data diff:#{differ.diff_as_object(expected_event.expected_data, event_with_correct_type.data)}"
          end
        end

        def metadata_diff(expected_event, event_with_correct_type)
          if expected_event.expected_metadata.nil?
            ""
          else
            "metadata diff:#{differ.diff_as_object(expected_event.expected_metadata, event_with_correct_type.metadata.to_h)}"
          end
        end
      end

      def initialize(mandatory_expected, *optional_expected, differ:, phraser:, failure_message_formatter: CrudeFailureMessageFormatter)
        @expected  = [mandatory_expected, *optional_expected]
        @matcher   = ::RSpec::Matchers::BuiltIn::Include.new(*expected)
        @differ    = differ
        @phraser   = phraser
        @failure_message_formatter = failure_message_formatter.new(@differ)
      end

      def matches?(event_store)
        raise NotSupported if count && count < 1
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
        failure_message_formatter.failure_message(matcher, expected, events, count, strict?)
      end

      def failure_message_when_negated
        failure_message_formatter.negated_failure_message(matcher, expected, events, count, strict?)
      end

      def description
        "have published events that have to (#{phraser.(expected)})"
      end

      def strict
        @matcher = ::RSpec::Matchers::BuiltIn::Match.new(expected)
        self
      end

      private

      def strict?
        matcher.is_a?(::RSpec::Matchers::BuiltIn::Match)
      end

      def matches_count?
        return true unless count
        raise NotSupported if expected.size > 1
        events.select { |e| expected.first === e }.size.equal?(count)
      end

      attr_reader :differ, :phraser, :stream_name, :expected, :count, :events, :start, :failure_message_formatter, :matcher
    end
  end
end
