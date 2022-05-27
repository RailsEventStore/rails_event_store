# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class CrudeFailureMessageFormatter
      class HavePublished
        def initialize(differ)
          @differ = differ
        end

        def failure_message(expected, events, stream_name)
          stream_expectation = " in stream #{stream_name}" unless stream_name.nil?
          "expected #{expected.events} to be published#{stream_expectation}, diff:" +
            differ.diff(expected.events.to_s + "\n", events)
        end

        def failure_message_when_negated(expected, events, stream_name)
          stream_expectation = " in stream #{stream_name}" unless stream_name.nil?
          "expected #{expected.events} not to be published#{stream_expectation}, diff:" +
            differ.diff(expected.events.to_s + "\n", events)
        end

        private

        attr_reader :differ
      end

      class Publish
        def failure_message(expected, events, stream)
          if !expected.empty?
            <<~EOS
            expected block to have published:

            #{expected.events}

            #{"in stream #{stream} " if stream}but published:

            #{events}
            EOS
          else
            "expected block to have published any events"
          end
        end

        def failure_message_when_negated(expected, events, stream)
          if !expected.empty?
            <<~EOS
            expected block not to have published:

            #{expected.events}

            #{"in stream #{stream} " if stream}but published:

            #{events}
            EOS
          else
            "expected block not to have published any events"
          end
        end
      end

      class HaveApplied
        def initialize(differ)
          @differ = differ
        end

        def failure_message(expected, events)
          "expected #{expected.events} to be applied, diff:" + differ.diff(expected.events.to_s + "\n", events)
        end

        def failure_message_when_negated(expected, events)
          "expected #{expected.events} not to be applied, diff:" + differ.diff(expected.events.inspect + "\n", events)
        end

        attr_reader :differ
      end

      class Apply
        def failure_message(expected, applied_events)
          if !expected.empty?
            <<~EOS
            expected block to have applied:

            #{expected.events}

            but applied:

            #{applied_events}
            EOS
          else
            "expected block to have applied any events"
          end
        end

        def failure_message_when_negated(expected, applied_events)
          if !expected.empty?
            <<~EOS
            expected block not to have applied:

            #{expected.events}

            but applied:

            #{applied_events}
            EOS
          else
            "expected block not to have applied any events"
          end
        end
      end

      def have_published(differ)
        HavePublished.new(differ)
      end

      def publish(_differ)
        Publish.new
      end

      def have_applied(differ)
        HaveApplied.new(differ)
      end

      def apply(_differ)
        Apply.new
      end
    end
  end
end
