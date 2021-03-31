module RubyEventStore
  module RSpec
    class ExpectedCollection
      def initialize(events)
        @events = events
        @strict = false
      end

      def exactly(count)
        raise NotSupported if events.size != 1
        raise NotSupported if count < 1
        @count = count
      end

      def once
        exactly(1)
      end

      def specified_count?
        !@count.nil?
      end

      def strict
        @strict = true
      end

      def strict?
        @strict == true
      end

      def event
        raise "Many events present in scenario where exactly one expected event was required" if events.size > 1
        events.first
      end

      attr_reader :events, :count
    end
  end
end
