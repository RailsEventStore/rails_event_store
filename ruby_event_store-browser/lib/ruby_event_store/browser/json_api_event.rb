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
            metadata: event.metadata.to_h
          }
        }
      end

      private
      attr_reader :event
    end
  end
end