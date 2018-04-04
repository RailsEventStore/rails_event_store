module RailsEventStore
  module Browser
    class EventsController < ApplicationController
      def show
        event = event_store.read_event(event_id)
        render json: { data: serialize_event(event) }, content_type: 'application/vnd.api+json'
      end

      private

      def event_id
        params.fetch(:id)
      end

      def serialize_event(event)
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
    end
  end
end
