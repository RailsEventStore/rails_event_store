module RailsEventStore
  module RSpec
    class EventMatcher
      def initialize(expected)
        @expected = expected
      end

      def matches?(actual)
        @actual = actual
        [matches_kind, matches_data].all?
      end

      def with_data(expected_data)
        @expected_data = expected_data
        self
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

      private

      def matches_kind
        @expected === @actual
      end

      def matches_data
        return true unless @expected_data
        @expected_data.all? { |k, v| @actual.data[k].eql?(v) }
      end
    end
  end
end

