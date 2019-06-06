module RubyEventStore
  module Browser
    class JsonApiEvent
      def initialize(event, url_builder)
        @event = event
        @url_builder = url_builder
      end

      def to_h
        {
          id: event.event_id,
          type: "events",
          attributes: {
            event_type: event.class.to_s,
            data: event.data,
            metadata: metadata
          },
          links: links,
        }
      end

      private
      attr_reader :event, :url_builder

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

      def links
        {}.tap do |h|
          h[:correlation_stream] = url_builder.call(
            id: "$by_correlation_id_#{event.metadata.fetch(:correlation_id)}",
          ) if event.metadata.has_key?(:correlation_id)
        end
      end
    end
  end
end
