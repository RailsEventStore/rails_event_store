module RailsEventStore
  module Browser
    class StreamsController < ApplicationController
      def index
        streams = Rails.configuration.event_store.get_all_streams
        render json: { data: streams.map { |s| serialize_stream(s) } }, content_type: 'application/vnd.api+json'
      end

      def show
        events = Rails.configuration.event_store.read_stream_events_backward(stream_name)
        render json: { data: events.map { |e| serialize_event(e) } }, content_type: 'application/vnd.api+json'
      end

      private

      def stream_name
        params.fetch(:id)
      end

      def serialize_stream(stream)
        {
          id: stream.name,
          type: "streams"
        }
      end

      def serialize_event(event)
        {
          id: event.event_id,
          type: "events",
          attributes: {
            event_type: event.class.to_s,
            data: event.data,
            metadata: event.metadata
          }
        }
      end
    end
  end
end