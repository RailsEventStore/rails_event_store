require 'rspec/matchers/built_in/base_matcher'

module RailsEventStore
  module RSpec
    class Publish < ::RSpec::Matchers::BuiltIn::BaseMatcher
      def in(event_store, &block)
        @event_store = event_store
        @block = block if block_given?
        self
      end

      def in_stream(stream, &block)
        @stream = stream
        @block = block if block_given?
        self
      end

      def matches?(event_proc)
        raise_event_store_not_set unless @event_store
        @event_proc = event_proc
        return false unless Proc === event_proc
        spec = @event_store.read
        spec = spec.stream(@stream) if @stream
        last_event_before_block = spec.backward.limit(1).each.to_a.first
        event_proc.call
        spec = spec.from(last_event_before_block.event_id) if last_event_before_block
        @published_events = spec.each.to_a
        if @block
          @block.call(@published_events)
        elsif @event
          ::RSpec::Matchers::BuiltIn::Include.new(*@event).matches?(@published_events)
        else
          !@published_events.empty?
        end
      end

      def does_not_match?(event_proc)
        !matches?(event_proc) && Proc === event_proc
      end

      def failure_message
        if @event
          <<-EOS
  expected block to have published:

  #{@event.inspect}

  #{"in stream #{@stream} " if @stream}but published:

  #{@published_events.inspect}
          EOS
        else
          "expected block to have published any events"
        end
      end

      def failure_message_when_negated
        if @event
          <<-EOS
  expected block not to have published:

  #{@event.inspect}

  #{"in stream #{@stream} " if @stream}but published:

  #{@published_events.inspect}
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

      def initialize(event = nil, &block)
        @event = event
        @stream = nil
        @event_store = nil
        @block = block
      end

      def raise_event_store_not_set
        raise SyntaxError, "You have to set the event store instance with `in`, e.g. `expect { ... }.to publish(an_event(MyEvent)).in(event_store)`"
      end
    end
  end
end
