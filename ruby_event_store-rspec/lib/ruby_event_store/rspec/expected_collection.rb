module RubyEventStore
  module RSpec
    class ExpectedCollection
      def initialize(events)
        @events = events
      end

      def exactly(count)
        @count = count
      end

      def once
        exactly(1)
      end

      attr_reader :events, :count
    end
  end
end
