module RailsEventStore
  module RSpec
    class EventMatcher
      def initialize(expected)
        @expected = expected
      end

      def matches?(actual)
        @expected === actual
      end
    end
  end
end

