module RailsEventStore
  module Browser
    class StreamsController < ApplicationController
      def index
        data =
          RailsEventStoreActiveRecord::EventInStream
            .pluck(:stream)
            .uniq
            .map { |s| { name: s } }
        render json: data
      end

      def show
        render json: []
      end

      private

      def event_store
        Rails.configuration.event_store
      end
    end
  end
end