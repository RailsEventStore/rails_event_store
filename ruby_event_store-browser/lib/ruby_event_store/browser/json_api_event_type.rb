# frozen_string_literal: true

module RubyEventStore
  module Browser
    class JsonApiEventType
      def initialize(event_type)
        @event_type = event_type
      end

      def to_h
        {
          id: event_type.event_type,
          type: "event_types",
          attributes: {
            event_type: event_type.event_type,
            stream_name: event_type.stream_name,
          },
        }
      end

      private

      attr_reader :event_type
    end
  end
end
