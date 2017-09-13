module RailsEventStore
  module RSpec
    class HaveApplied
      def initialize(expected)
        @expected = expected
        @matcher  = ::RSpec::Matchers::BuiltIn::Include.new(@expected)
      end

      def matches?(aggregate_root)
        events = aggregate_root.__send__(:unpublished_events)
        @matcher.matches?(events) && matches_count(events, @expected, @count)
      end

      def exactly(count)
        @count = count
        self
      end

      private

      def matches_count(events, expected, count)
        return true unless count
        events.select { |e| expected === e }.size.equal?(count)
      end
    end
  end
end

