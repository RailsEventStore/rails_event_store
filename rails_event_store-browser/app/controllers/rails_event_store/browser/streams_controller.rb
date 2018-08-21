module RailsEventStore
  module Browser
    class StreamsController < ApplicationController
      def show
        stream = RubyEventStore::Browser::Stream.new(
          event_store: event_store,
          params: params,
          url_builder: public_method(:stream_url)
        )

        render json: stream.as_json, content_type: 'application/vnd.api+json'
      end
    end
  end
end