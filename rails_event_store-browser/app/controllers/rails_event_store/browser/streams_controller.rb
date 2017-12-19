module RailsEventStore
  module Browser
    class StreamsController < ApplicationController
      def index
        render json: event_store.get_all_streams.map { |s| serialize_stream(s) }
      end

      def show
        events = event_store.read_stream_events_backward(stream_name)
        render json: events.map { |e| serialize_event(e) }
      end

      private

      def stream_name
        params[:id]
      end

      def serialize_stream(stream)
        { name: stream.name }
      end

      def serialize_event(event)
        {
          event_id: event.event_id,
          event_type: event.class.to_s,
          data: event.data,
          metadata: event.metadata
        }
      end

      def event_store
        Rails.configuration.event_store
      end
    end
  end
end