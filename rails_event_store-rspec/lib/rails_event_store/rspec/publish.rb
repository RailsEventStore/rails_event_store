# frozen_string_literal: true

module RailsEventStore
  module RSpec
    class Publish
      def in(event_store)
        @event_store = event_store
        self
      end

      def in_stream(stream)
        @stream = stream
        self
      end

      def matches?(event_proc)
        raise_event_store_not_set unless @event_store
        spec = @event_store.read
        spec = spec.stream(@stream) if @stream
        last_event_before_block = spec.last
        event_proc.call
        spec = spec.from(last_event_before_block.event_id) if last_event_before_block
        @published_events = spec.to_a
        if match_events?
          ::RSpec::Matchers::BuiltIn::Include.new(*@expected).matches?(@published_events)
        else
          !@published_events.empty?
        end
      end

      def failure_message
        if match_events?
          <<-EOS
expected block to have published:

#{@expected}

#{"in stream #{@stream} " if @stream}but published:

#{@published_events}
EOS
        else
          "expected block to have published any events"
        end
      end

      def failure_message_when_negated
        if match_events?
          <<-EOS
expected block not to have published:

#{@expected}

#{"in stream #{@stream} " if @stream}but published:

#{@published_events}
EOS
        else
          "expected block not to have published any events"
        end
      end

      def description
        "publish events"
      end

      def supports_block_expectations?
        true
      end

      private

      def initialize(*expected)
        @expected = expected
      end

      def match_events?
        !@expected.empty?
      end

      def raise_event_store_not_set
        raise SyntaxError, "You have to set the event store instance with `in`, e.g. `expect { ... }.to publish(an_event(MyEvent)).in(event_store)`"
      end
    end
  end
end
