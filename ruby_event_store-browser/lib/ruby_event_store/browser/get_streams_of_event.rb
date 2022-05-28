# frozen_string_literal: true

module RubyEventStore
  module Browser
    class GetStreamsOfEvent
      attr_reader :event_store, :params

      def initialize(event_store:, params:)
        @event_store = event_store
        @params = params
      end

      def as_json
        {
          data: JsonApiStreamsOfEvent.new(event.event_id, streams_of_event).to_h
        }
      end


      def event
        @event ||= event_store.read.event!(event_id)
      end


      def streams_of_event_names
        event_store.streams_of(event_id).map(&:name)
      end

      def streams_of_event
        streams_of_event_names.map do |other_stream|
          "$by_#{other_stream}_#{event.event_id}"
        end
      end

      def event_id
        params.fetch(:id)
      end
    end
  end
end
