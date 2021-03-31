module RubyEventStore
  module RSpec
    class FetchEvents
      def from(event_id)
        @start = event_id
      end

      def stream(stream_name)
        @stream_name = stream_name
      end

      def in(event_store)
        @event_store = event_store
      end

      def event_store?
        !@event_store.nil?
      end

      def call
        events = event_store.read
        events = events.stream(stream_name) if stream_name
        events = events.from(start) if start
        events.each
      end

      attr_reader :start, :stream_name, :event_store
    end
  end
end
