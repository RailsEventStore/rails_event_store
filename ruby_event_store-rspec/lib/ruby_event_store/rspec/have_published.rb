# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class HavePublished
      class CrudeFailureMessageFormatter
        def initialize(differ)
          @differ = differ
        end

        def failure_message(expected, events, _expected_count, _strict)
          "expected #{expected} to be published, diff:" +
            differ.diff(expected.to_s + "\n", events.to_a.to_s + "\n")
        end

        def negated_failure_message(expected, events, _expected_count, _strict)
          "expected #{expected} not to be published, diff:" +
            differ.diff(expected.to_s + "\n", events.to_a.to_s + "\n")
        end

        private
        attr_reader :differ
      end

      class StepByStepFailureMessageFormatter
        def initialize(differ)
          @differ = differ
        end

        def failure_message(expected, events, expected_count, strict)
          return failure_message_strict(expected, events, expected_count) if strict
          expected.each do |expected_event|
            correct_event_count = 0
            events_with_correct_type = []
            events.each do |actual_event|
              if expected_event.matches?(actual_event)
                correct_event_count += 1
              elsif expected_event.matches_kind?(actual_event)
                events_with_correct_type << actual_event
              end
            end

            if expected_count
              if correct_event_count == expected_count
                next
              elsif correct_event_count >= 1
                return failure_message_incorrect_count(expected, expected_event, expected_count, events_with_correct_type, correct_event_count)
              elsif !events_with_correct_type.empty?
                return failure_message_correct_type_incorrect_payload(expected, expected_event, expected_count, events_with_correct_type)
              else
                return failure_message_incorrect_type(expected, expected_event, expected_count)
              end
            else
              if correct_event_count >= 1
                next
              elsif !events_with_correct_type.empty?
                return failure_message_correct_type_incorrect_payload(expected, expected_event, expected_count, events_with_correct_type)
              else
                return failure_message_incorrect_type(expected, expected_event, expected_count)
              end
            end
          end
        end

        def negated_failure_message(expected, events, expected_count, strict)
          if expected_count
            <<~EOS
            expected
              #{expected.fetch(0).description}
            not to be published exactly #{expected_count} times

            #{actual_events_list(events)}
            EOS
          else
            <<~EOS
            expected #{expected_events_list(expected)} not to be #{"exactly " if strict}published

            #{actual_events_list(events)}
            EOS
          end
        end

        private
        attr_reader :differ

        def failure_message_incorrect_count(expected, expected_event, expected_count, events_with_correct_type, correct_event_count)
          [
            <<~EOS,
            #{expected_message(expected, expected_event, expected_count)}
            but was published #{correct_event_count} times
            EOS

            !events_with_correct_type.empty? ? [
              <<~EOS.strip,
              There are events of correct type but with incorrect payload:
              EOS
              *events_with_correct_type.each_with_index.map {|event_with_correct_type, index| event_diff(expected_event, event_with_correct_type, index) },
              ""
            ].join("\n") : nil
          ].compact.join("\n")
        end

        def failure_message_correct_type_incorrect_payload(expected, expected_event, expected_count, events_with_correct_type)
          [
          <<~EOS.strip,
          #{expected_message(expected, expected_event, expected_count)}, but it was not published

          There are events of correct type but with incorrect payload:
          EOS
          *events_with_correct_type.each_with_index.map {|event_with_correct_type, index| event_diff(expected_event, event_with_correct_type, index) },
          ""
          ].join("\n")
        end

        def event_diff(expected_event, event_with_correct_type, index)
          [
            "#{index + 1}) #{event_with_correct_type.inspect}",
            indent(data_diff(expected_event, event_with_correct_type), 4),
            indent(metadata_diff(expected_event, event_with_correct_type), 4),
          ].reject(&:empty?).join("\n")
        end

        def indent(str, count)
          str.to_s.split("\n").map {|l| l.sub(//, " " * count) }.join("\n")
        end

        def failure_message_incorrect_type(expected, expected_event, expected_count)
          <<~EOS
          #{expected_message(expected, expected_event, expected_count)}, but there is no event with such type
          EOS
        end

        def failure_message_strict(expected, events, expected_count)
          if expected_count
            <<~EOS
            expected only
              #{expected.fetch(0).description}
            to be published #{expected_count} times

            #{actual_events_list(events)}
            EOS
          else
            <<~EOS
            expected only #{expected_events_list(expected)} to be published

            #{actual_events_list(events)}
            EOS
          end
        end

        def data_diff(expected_event, event_with_correct_type)
          if !expected_event.expected_data.nil?
            "data diff:#{differ.diff(expected_event.expected_data, event_with_correct_type.data)}".strip
          end
        end

        def metadata_diff(expected_event, event_with_correct_type)
          if !expected_event.expected_metadata.nil?
            "metadata diff:#{differ.diff(expected_event.expected_metadata, event_with_correct_type.metadata.to_h)}".strip
          end
        end

        def expected_message(expected, expected_event, expected_count)
          if expected_count
            <<~EOS
            expected event
              #{expected_event.description}
            to be published #{expected_count} times
            EOS
          else
            <<~EOS
            expected #{expected_events_list(expected)} to be published

            i.e. expected event
              #{expected_event.description}
            to be published
            EOS
          end.strip
        end

        def expected_events_list(expected)
          <<~EOS.strip
          [
          #{expected.map(&:description).map {|d| indent(d, 2) }.join("\n")}
          ]
          EOS
        end

        def actual_events_list(actual)
          <<~EOS.strip
          but the following was published: [
          #{actual.map(&:inspect).map {|d| indent(d, 2) }.join("\n")}
          ]
          EOS
        end
      end

      @@default_formatter = CrudeFailureMessageFormatter

      def self.default_formatter=(new_formatter)
        @@default_formatter = new_formatter
      end

      def self.default_formatter
        @@default_formatter
      end

      def initialize(mandatory_expected, *optional_expected, differ:, phraser:, failure_message_formatter: @@default_formatter)
        @expected  = [mandatory_expected, *optional_expected]
        @matcher   = ::RSpec::Matchers::BuiltIn::Include.new(*expected)
        @phraser   = phraser
        @failure_message_formatter = failure_message_formatter.new(differ)
      end

      def matches?(event_store)
        raise NotSupported if count && count < 1
        @events = event_store.read
        @events = events.stream(stream_name) if stream_name
        @events = events.from(start)         if start
        @events = events.each
        matcher.matches?(events) && matches_count?
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
        failure_message_formatter.failure_message(expected, events, count, strict?)
      end

      def failure_message_when_negated
        failure_message_formatter.negated_failure_message(expected, events, count, strict?)
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
        matcher.instance_of?(::RSpec::Matchers::BuiltIn::Match)
      end

      def matches_count?
        return true unless count
        raise NotSupported if expected.size > 1
        events.select { |e| expected.first === e }.size.equal?(count)
      end

      attr_reader :phraser, :stream_name, :expected, :count, :events, :start, :failure_message_formatter, :matcher
    end
  end
end
