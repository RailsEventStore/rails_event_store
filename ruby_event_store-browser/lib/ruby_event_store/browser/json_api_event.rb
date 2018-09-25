module RubyEventStore
  module Browser
    class JsonApiEvent
      def initialize(event)
        @event = event
      end

      def to_h
        {
          id: event.event_id,
          type: "events",
          attributes: {
            event_type: event.class.to_s,
            data: event.data,
            metadata: metadata
          }
        }
      end

      private
      attr_reader :event

      def metadata
        event.metadata.to_h.tap do |m|
          m[:timestamp] = m[:timestamp].iso8601(3) if m[:timestamp]
        end
      end
    end
  end
end