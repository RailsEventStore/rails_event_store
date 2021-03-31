module RubyEventStore
  module RSpec
    class ExpectedCollection
      def initialize(events)
        @events = events
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

      attr_reader :events, :count
    end
  end
end
