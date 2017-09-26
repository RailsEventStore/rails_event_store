module RailsEventStore
  module RSpec
    class HavePublished
      def initialize(expected, *expecteds, differ:)
        @expected = [expected, *expecteds]
        @matcher  = ::RSpec::Matchers::BuiltIn::Include.new(*@expected)
        @differ   = differ
      end

      def matches?(event_store)
        @events = @stream_name ? event_store.read_events_backward(@stream_name)
                              : event_store.read_all_streams_backward
        @matcher.matches?(@events) && matches_count(@events, @expected, @count)
      end

      def exactly(count)
        @count = count
        self
      end

      def in_stream(stream_name)
        @stream_name = stream_name
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
        differ.diff_as_string(@expected.to_s, @events.to_s)
      end

      private

      attr_reader :differ

      def matches_count(events, expected, count)
        return true unless count
        raise NotSupported if expected.size > 1

        expected.all? do |event_or_matcher|
          events.select { |e| event_or_matcher === e }.size.equal?(count)
        end
      end
    end
  end
end
