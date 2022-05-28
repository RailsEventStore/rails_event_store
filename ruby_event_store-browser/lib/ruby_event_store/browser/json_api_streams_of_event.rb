# frozen_string_literal: true

module RubyEventStore
  module Browser
    class JsonApiStreamsOfEvent
      def initialize(event_id, streams_of_event)
        @event_id = event_id
        @streams_of_event = streams_of_event
      end

      def to_h
        {
          id: event_id,
          type: "streams",
          attributes:
            { streams_of_event: streams_of_event }
        }
      end

      private

      attr_reader :event_id, :streams_of_event
    end
  end
end

