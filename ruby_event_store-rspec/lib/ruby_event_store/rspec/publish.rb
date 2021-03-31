# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class Publish
      class CrudeFailureMessageFormatter
        def failure_message(expected, events, stream)
          if match_events?(expected)
            <<~EOS
            expected block to have published:

            #{expected}

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

            #{expected}

            #{"in stream #{stream} " if stream}but published:

            #{events}
            EOS
          else
            "expected block not to have published any events"
          end
        end

        def match_events?(expected)
          !expected.empty?
        end
      end

      def in(event_store)
        @event_store = event_store
        self
      end

      def in_stream(stream)
        @stream = stream
        self
      end

      def exactly(count)
        @expected.exactly(count)
        self
      end

      def once
        @expected.once
        self
      end

      def times
        self
      end
      alias :time :times

      def matches?(event_proc)
        raise_event_store_not_set unless @event_store
        spec = @event_store.read
        spec = spec.stream(@stream) if @stream
        last_event_before_block = spec.last
        event_proc.call
        spec = spec.from(last_event_before_block.event_id) if last_event_before_block
        @published_events = spec.to_a
        raise NotSupported if count && @expected.events.size != 1
        if match_events?
          ::RSpec::Matchers::BuiltIn::Include.new(*@expected.events).matches?(@published_events) && matches_count?
        else
          !@published_events.empty?
        end
      end

      def failure_message
        @failure_message_formatter.failure_message(@expected.events, @published_events, @stream)
      end

      def failure_message_when_negated
        @failure_message_formatter.negated_failure_message(@expected.events, @published_events, @stream)
      end

      def description
        "publish events"
      end

      def supports_block_expectations?
        true
      end

      private

      def count
        @expected.count
      end

      def initialize(*expected)
        @expected = ExpectedCollection.new(expected)
        @failure_message_formatter = CrudeFailureMessageFormatter.new
      end

      def match_events?
        !@expected.events.empty?
      end

      def raise_event_store_not_set
        raise SyntaxError, "You have to set the event store instance with `in`, e.g. `expect { ... }.to publish(an_event(MyEvent)).in(event_store)`"
      end

      def matches_count?
        return true unless count
        @published_events.select { |e| @expected.events.first === e }.size.equal?(count)
      end
    end
  end
end
