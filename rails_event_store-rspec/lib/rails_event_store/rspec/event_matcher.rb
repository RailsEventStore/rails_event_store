module RailsEventStore
  module RSpec
    class EventMatcher
      def initialize(expected)
        @expected = expected
      end

      def matches?(actual)
        @actual = actual
        @expected === @actual
      end

      def failure_message
        %Q{
expected: #{@expected}
     got: #{@actual.class}
}
      end

      def failure_message_when_negated
        %Q{
expected: not a kind of #{@expected}
     got: #{@actual.class}
}
      end
    end
  end
end

