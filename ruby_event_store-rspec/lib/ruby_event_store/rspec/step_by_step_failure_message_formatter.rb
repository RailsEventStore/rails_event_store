# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class StepByStepFailureMessageFormatter
      class Lingo
        def initialize(published)
          @published = published
        end
        attr_reader :published
      end

      class HavePublished
        def initialize(differ, lingo)
          @differ = differ
          @lingo = lingo
        end

        def failure_message(expected, events, stream_name = nil)
          return failure_message_strict(expected, events) if expected.strict?
          return failure_message_no_events if expected.empty?
          expected.events.each do |expected_event|
            correct_event_count = 0
            events_with_correct_type = []
            events.each do |actual_event|
              if expected_event.matches?(actual_event)
                correct_event_count += 1
              elsif expected_event.matches_kind?(actual_event)
                events_with_correct_type << actual_event
              end
            end

            expectations = expected_message(expected, expected_event, stream_name)

            if expected.specified_count?
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

            return expectations + reality
          end
        end

        def failure_message_when_negated(expected, events, _stream_name = nil)
          return failure_message_when_negated_no_events if expected.empty?
          if expected.specified_count?
            <<~EOS
            expected
              #{expected.events.first.description}
            not to be #{lingo.published} exactly #{expected.count} times

            #{actual_events_list(events)}
            EOS
          else
            <<~EOS
            expected #{expected_events_list(expected.events)} not to #{"exactly " if expected.strict?}be #{lingo.published}

            #{actual_events_list(events)}
            EOS
          end
        end

        private

        attr_reader :differ, :lingo

        def failure_message_no_events
          "expected anything to be #{lingo.published}\n"
        end

        def failure_message_when_negated_no_events
          "expected something to be #{lingo.published}\n"
        end

        def failure_message_incorrect_count(expected_event, events_with_correct_type, correct_event_count)
          [
            <<~EOS,

            but was #{lingo.published} #{correct_event_count} times
            EOS
            if !events_with_correct_type.empty?
              [
                <<~EOS.strip,
              There are events of correct type but with incorrect payload:
                EOS
                events_with_correct_type.each_with_index.map do |event_with_correct_type, index|
                  event_diff(expected_event, event_with_correct_type, index)
                end,
                nil,
              ]
            end,
          ].compact.join("\n")
        end

        def failure_message_correct_type_incorrect_payload(expected_event, events_with_correct_type)
          <<~EOS
          , but it was not #{lingo.published}

          There are events of correct type but with incorrect payload:
          #{events_with_correct_type.each_with_index.map { |event_with_correct_type, index| event_diff(expected_event, event_with_correct_type, index) }.join("\n")}
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
          str.to_s.split("\n").map { |l| l.sub(//, " " * count) }
        end

        def failure_message_incorrect_type
          <<~EOS
          , but there is no event with such type
          EOS
        end

        def failure_message_strict(expected, events)
          if expected.specified_count?
            <<~EOS
            expected only
              #{expected.events.first.description}
            to be #{lingo.published} #{expected.count} times

            #{actual_events_list(events)}
            EOS
          else
            <<~EOS
            expected only #{expected_events_list(expected.events)} to be #{lingo.published}

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

        def expected_message(expected, expected_event, stream_name)
          expected_stream = " in stream #{stream_name}" if stream_name
          if expected.specified_count?
            <<~EOS
            expected event
              #{expected_event.description}
            to be #{lingo.published} #{expected.count} times#{expected_stream}
            EOS
          else
            <<~EOS
            expected #{expected_events_list(expected.events)} to be #{lingo.published}#{expected_stream}

            i.e. expected event
              #{expected_event.description}
            to be #{lingo.published}
            EOS
          end.strip
        end

        def expected_events_list(expected)
          <<~EOS.strip
          [
          #{expected.map(&:description).map { |d| indent(d, 2) }.join("\n")}
          ]
          EOS
        end

        def actual_events_list(actual)
          <<~EOS.strip
          but the following was #{lingo.published}: [
          #{actual.map(&:inspect).map { |d| indent(d, 2) }.join("\n")}
          ]
          EOS
        end
      end

      def have_published(differ)
        HavePublished.new(differ, Lingo.new("published"))
      end

      def publish(differ)
        HavePublished.new(differ, Lingo.new("published"))
      end

      def have_applied(differ)
        HavePublished.new(differ, Lingo.new("applied"))
      end

      def apply(differ)
        HavePublished.new(differ, Lingo.new("applied"))
      end
    end
  end
end
