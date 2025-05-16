# frozen_string_literal: true

module RubyEventStore
  module Browser
    class JsonApiEvent
      def initialize(event, parent_event_id)
        @event = event
        @parent_event_id = parent_event_id
      end

      def to_h
        {
          id: event.event_id,
          type: "events",
          attributes: {
            event_type: event.event_type,
            data: sanitize_infinity_values(event.data),
            metadata: metadata,
            correlation_stream_name: correlation_stream_name,
            causation_stream_name: causation_stream_name,
            type_stream_name: type_stream_name,
            parent_event_id: parent_event_id,
          },
        }
      end

      private

      attr_reader :event, :parent_event_id

      def sanitize_infinity_values(value)
        case value
        in Hash => hash
          hash.transform_values { |v| sanitize_infinity_values(v) }
        in Array => array
          array.map { |v| sanitize_infinity_values(v) }
        in Float => f if f.infinite?
          f.positive? ? "Infinity" : "-Infinity"
        in Float => f if f.nan?
          "NaN"
        else
          value
        end
      end

      def metadata
        event.metadata.to_h.tap do |m|
          m[:timestamp] = event.metadata.fetch(:timestamp).iso8601(TIMESTAMP_PRECISION)
          m[:valid_at] = event.metadata.fetch(:valid_at).iso8601(TIMESTAMP_PRECISION)
        end
      end

      def correlation_stream_name
        "$by_correlation_id_#{metadata.fetch(:correlation_id)}" if metadata.has_key?(:correlation_id)
      end

      def causation_stream_name
        "$by_causation_id_#{event.event_id}"
      end

      def type_stream_name
        "$by_type_#{event.event_type}"
      end
    end
  end
end
