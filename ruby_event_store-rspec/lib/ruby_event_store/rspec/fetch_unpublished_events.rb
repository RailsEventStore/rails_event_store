module RubyEventStore
  module RSpec
    class FetchUnpublishedEvents
      def in(aggregate)
        @aggregate = aggregate
      end

      def call
        aggregate.unpublished_events.to_a
      end

      attr_reader :aggregate
    end
  end
end
