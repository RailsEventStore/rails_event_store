module RailsEventStore
  module Browser
    class StreamsController < ApplicationController
      def index
        render json: event_store.get_all_streams.map { |s| serialize_stream(s) }
      end

      def show
        render json: []
      end

      private

      def serialize_stream(stream)
        { name: stream.name }
      end

      def event_store
        Rails.configuration.event_store
      end
    end
  end
end