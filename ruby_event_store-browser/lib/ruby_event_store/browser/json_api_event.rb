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
            metadata: metadata,
            correlation_stream_name: correlation_stream_name,
          },
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

      def correlation_stream_name
        "$by_correlation_id_#{event.metadata.fetch(:correlation_id)}" if event.metadata.has_key?(:correlation_id)
      end
    end
  end
end
