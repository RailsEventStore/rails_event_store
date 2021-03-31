# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class Publish
      class CrudeFailureMessageFormatter
        def failure_message(expected, events, stream)
          if match_events?(expected)
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

        def negated_failure_message(expected, events, stream)
          if match_events?(expected)
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

        def match_events?(expected)
          !expected.events.empty?
        end
      end

      def initialize(*expected)
        @expected = ExpectedCollection.new(expected)
        @failure_message_formatter = CrudeFailureMessageFormatter.new
        @fetch_events = FetchEvents.new
      end

      def in(event_store)
        fetch_events.in(event_store)
        self
      end

      def in_stream(stream)
        fetch_events.stream(stream)
        self
      end

      def exactly(count)
        expected.exactly(count)
        self
      end

      def once
        expected.once
        self
      end

      def times
        self
      end
      alias :time :times

      def matches?(event_proc)
        fetch_events.from_last
        event_proc.call
        @published_events = fetch_events.call.to_a
        if match_events?
          ::RSpec::Matchers::BuiltIn::Include.new(*expected.events).matches?(@published_events) && matches_count?
        else
          !@published_events.empty?
        end
      rescue FetchEvents::MissingEventStore
        raise SyntaxError, "You have to set the event store instance with `in`, e.g. `expect { ... }.to publish(an_event(MyEvent)).in(event_store)`"
      end

      def failure_message
        failure_message_formatter.failure_message(expected, @published_events, fetch_events.stream_name)
      end

      def failure_message_when_negated
        failure_message_formatter.negated_failure_message(expected, @published_events, fetch_events.stream_name)
      end

      def description
        "publish events"
      end

      def supports_block_expectations?
        true
      end

      private

      def count
        expected.count
      end

      def match_events?
        !expected.events.empty?
      end

      def matches_count?
        return true unless count
        @published_events.select { |e| expected.events.first === e }.size.equal?(count)
      end

      attr_reader :fetch_events, :expected, :failure_message_formatter
    end
  end
end
