# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class Apply
      def initialize(*expected)
        @expected = ExpectedCollection.new(expected)
      end

      def in(aggregate)
        @aggregate = aggregate
        self
      end

      def strict
        expected.strict
        self
      end

      def matches?(event_proc)
        raise_aggregate_not_set unless @aggregate
        before = @aggregate.unpublished_events.to_a
        event_proc.call
        @applied_events = @aggregate.unpublished_events.to_a - before
        if match_events?
          matcher.matches?(applied_events)
        else
          !applied_events.empty?
        end
      end

      def failure_message
        if match_events?
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

      def failure_message_when_negated
        if match_events?
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

      def description
        "apply events"
      end

      def supports_block_expectations?
        true
      end

      private

      def matcher
        expected.strict? ?
          ::RSpec::Matchers::BuiltIn::Match.new(expected.events) :
          ::RSpec::Matchers::BuiltIn::Include.new(*expected.events)
      end

      def match_events?
        !expected.events.empty?
      end

      def raise_aggregate_not_set
        raise SyntaxError, "You have to set the aggregate instance with `in`, e.g. `expect { ... }.to apply(an_event(MyEvent)).in(aggregate)`"
      end

      attr_reader :expected, :applied_events
    end
  end
end
