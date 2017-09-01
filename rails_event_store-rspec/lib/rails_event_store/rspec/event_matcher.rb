module RailsEventStore
  module RSpec
    class EventMatcher
      class FailureMessage
        def initialize(expected_klass, actual_klass, expected_data, actual_data)
          @expected_klass = expected_klass
          @actual_klass   = actual_klass
          @expected_data  = expected_data
          @actual_data    = actual_data
        end

        def to_s
          @expected_data ? failure_message_with_data : failure_message
        end

        private

        def failure_message
          %Q{
expected: #{@expected_klass}
     got: #{@actual_klass}
}
        end

        def failure_message_with_data
          %Q{
expected: #{@expected_klass} with data: #{@expected_data}
     got: #{@actual_klass} with data: #{@actual_data}
}
        end
      end

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
        FailureMessage.new(@expected, @actual.class, @expected_data, @actual.data).to_s
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

