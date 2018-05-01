module RailsEventStore
  module Browser
    class EventsController < ApplicationController
      def show
        event = event_store.read_event(event_id)
        render json: { data: JsonApiEvent.new(event).to_h }, content_type: 'application/vnd.api+json'
      end

      private

      def event_id
        params.fetch(:id)
      end
    end
  end
end
