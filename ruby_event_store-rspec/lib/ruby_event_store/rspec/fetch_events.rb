module RubyEventStore
  module RSpec
    class FetchEvents
      def from(event_id)
        @start = event_id
      end

      def stream(stream_name)
        @stream_name = stream_name
      end

      attr_reader :start, :stream_name
    end
  end
end
