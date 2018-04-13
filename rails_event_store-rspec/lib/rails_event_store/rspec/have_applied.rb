module RailsEventStore
  module RSpec
    class HaveApplied
      def initialize(expected, *expecteds, differ:)
        @expected = [expected, *expecteds]
        @matcher  = ::RSpec::Matchers::BuiltIn::Include.new(*expected())
        @differ   = differ
      end

      def matches?(aggregate_root)
        @events = aggregate_root.unpublished_events.to_a
        matcher.matches?(events) && matches_count?
      end

      def exactly(count)
        @count = count
        self
      end

      def times
        self
      end
      alias :time :times

      def once
        exactly(1)
      end

      def failure_message
        differ.diff_as_string(expected.to_s, events.to_s)
      end

      private

      def matches_count?
        return true unless count
        raise NotSupported if expected.size > 1

        expected.all? do |event_or_matcher|
          events.select { |e| event_or_matcher === e }.size.equal?(count)
        end
      end

      attr_reader :differ, :expected, :events, :count, :matcher
    end
  end
end

