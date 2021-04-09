module RubyEventStore
  module RSpec
    class ExpectedCollection
      def initialize(events)
        @events = events
        @strict = false
      end

      def exactly(count)
        raise NotSupported if !events.size.equal?(1)
        raise NotSupported if count < 1
        @count = count
      end

      def once
        exactly(1)
      end

      def specified_count?
        !count.nil?
      end

      def strict
        @strict = true
      end

      def strict?
        @strict
      end

      def event
        raise NotSupported if !events.size.equal?(1)
        events.first
      end

      attr_reader :events, :count
    end
  end
end
