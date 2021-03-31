# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class HavePublished
      class CrudeFailureMessageFormatter
        def initialize(differ)
          @differ = differ
        end

        def failure_message(expected, events, _expected_count, _strict, _stream_name)
          "expected #{expected} to be published, diff:" +
            differ.diff(expected.to_s + "\n", events.to_a)
        end

        def negated_failure_message(expected, events, _expected_count, _strict)
          "expected #{expected} not to be published, diff:" +
            differ.diff(expected.to_s + "\n", events.to_a)
        end

        private
        attr_reader :differ
      end

      class StepByStepFailureMessageFormatter
        def initialize(differ)
          @differ = differ
        end

        def failure_message(expected, events, expected_count, strict, stream_name)
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

            expectations = expected_message(expected, expected_event, expected_count, stream_name)

            if expected_count
              if correct_event_count >= 1
                reality = failure_message_incorrect_count(expected_event, events_with_correct_type, correct_event_count)
              elsif !events_with_correct_type.empty?
                reality = failure_message_correct_type_incorrect_payload(expected_event, events_with_correct_type)
              else
                reality = failure_message_incorrect_type
              end
            else
              if correct_event_count >= 1
                next
              else
                if !events_with_correct_type.empty?
                  reality = failure_message_correct_type_incorrect_payload(expected_event, events_with_correct_type)
                else
                  reality = failure_message_incorrect_type
                end
              end
            end

            return (expectations + reality)
          end
        end

        def negated_failure_message(expected, events, expected_count, strict)
          if expected_count
            <<~EOS
            expected
              #{expected.first.description}
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

        def failure_message_incorrect_count(expected_event, events_with_correct_type, correct_event_count)
          [
            <<~EOS,

            but was published #{correct_event_count} times
            EOS

            if !events_with_correct_type.empty?
              [
              <<~EOS.strip,
              There are events of correct type but with incorrect payload:
              EOS
              events_with_correct_type.each_with_index.map {|event_with_correct_type, index| event_diff(expected_event, event_with_correct_type, index) },
              nil
              ]
            end
          ].compact.join("\n")
        end

        def failure_message_correct_type_incorrect_payload(expected_event, events_with_correct_type)
          <<~EOS
          , but it was not published

          There are events of correct type but with incorrect payload:
          #{events_with_correct_type.each_with_index.map {|event_with_correct_type, index| event_diff(expected_event, event_with_correct_type, index) }.join("\n")}
          EOS
        end

        def event_diff(expected_event, event_with_correct_type, index)
          [
            "#{index + 1}) #{event_with_correct_type.inspect}",
            indent(data_diff(expected_event, event_with_correct_type), 4),
            indent(metadata_diff(expected_event, event_with_correct_type), 4),
          ].reject(&:empty?)
        end

        def indent(str, count)
          str.to_s.split("\n").map {|l| l.sub(//, " " * count) }
        end

        def failure_message_incorrect_type
          <<~EOS
          , but there is no event with such type
          EOS
        end

        def failure_message_strict(expected, events, expected_count)
          if expected_count
            <<~EOS
            expected only
              #{expected.first.description}
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
            "data diff:#{differ.diff(expected_event.expected_data, event_with_correct_type.data)}"
          end
        end

        def metadata_diff(expected_event, event_with_correct_type)
          if !expected_event.expected_metadata.nil?
            "metadata diff:#{differ.diff(expected_event.expected_metadata, event_with_correct_type.metadata.to_h)}"
          end
        end

        def expected_message(expected, expected_event, expected_count, stream_name)
          expected_stream = " in stream #{stream_name}" if stream_name
          if expected_count
            <<~EOS
            expected event
              #{expected_event.description}
            to be published #{expected_count} times#{expected_stream}
            EOS
          else
            <<~EOS
            expected #{expected_events_list(expected)} to be published#{expected_stream}

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

      def initialize(mandatory_expected, *optional_expected, differ:, phraser:, failure_message_formatter: RSpec.default_formatter.have_published)
        @expected  = ExpectedCollection.new([mandatory_expected, *optional_expected])
        @matcher   = ::RSpec::Matchers::BuiltIn::Include.new(*expected.events)
        @phraser   = phraser
        @failure_message_formatter = failure_message_formatter.new(differ)
      end

      def matches?(event_store)
        raise NotSupported if count && count < 1
        stream_names.all? do |stream_name|
          @events = event_store.read
          @events = events.stream(stream_name) if stream_name
          @events = events.from(start) if start
          @events = events.each
          @failed_on_stream = stream_name
          matcher.matches?(events) && matches_count?
        end
      end

      def exactly(count)
        @expected.exactly(count)
        self
      end

      def in_stream(stream_name)
        @stream_names = [stream_name]
        self
      end

      def in_streams(*stream_names)
        @stream_names = stream_names.flatten
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
        @expected.once
        self
      end

      def failure_message
        failure_message_formatter.failure_message(expected.events, events, count, strict?, failed_on_stream)
      end

      def failure_message_when_negated
        failure_message_formatter.negated_failure_message(expected.events, events, count, strict?)
      end

      def description
        "have published events that have to (#{phraser.(expected.events)})"
      end

      def strict
        @matcher = ::RSpec::Matchers::BuiltIn::Match.new(expected.events)
        self
      end

      private

      def count
        @expected.count
      end

      def strict?
        matcher.instance_of?(::RSpec::Matchers::BuiltIn::Match)
      end

      def matches_count?
        return true unless count
        raise NotSupported if expected.events.size > 1
        events.select { |e| expected.events.first === e }.size.equal?(count)
      end

      def stream_names
        @stream_names || [nil]
      end

      attr_reader :phraser, :expected, :events, :start, :failed_on_stream, :failure_message_formatter, :matcher
    end
  end
end
