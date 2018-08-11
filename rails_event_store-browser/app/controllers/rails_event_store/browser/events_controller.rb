module RailsEventStore
  module Browser
    class EventsController < ApplicationController
      def show
        event = RubyEventStore::Browser::Event.new(
          event_store: event_store,
          params: params
        )

        render json: event.as_json, content_type: 'application/vnd.api+json'
      end
    end
  end
end
