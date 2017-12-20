module RailsEventStore
  module Browser
    class EventsController < ApplicationController
      def show
        render json: serialize_event(Rails.configuration.event_store.read_event(event_id))
      end

      private

      def event_id
        params.fetch(:id)
      end

      def serialize_event(event)
        {
          event_id: event.event_id,
          event_type: event.class.to_s,
          data: event.data,
          metadata: event.metadata
        }
      end
    end
  end
end
