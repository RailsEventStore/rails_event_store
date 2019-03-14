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
            event_type: event.type,
            data: event.data,
            metadata: metadata
          }
        }
      end

      private
      attr_reader :event

      def metadata
        event.metadata.to_h.tap do |m|
          m[:timestamp] = as_time(m.fetch(:timestamp)).iso8601(3) if m.key?(:timestamp)
        end
      end

      def as_time(value)
        case value
        when String
          Time.parse(value)
        else
          value
        end
      end
    end
  end
end