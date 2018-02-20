module RailsEventStore
  module Browser
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception

      private

      def event_store
        Rails.configuration.event_store
      end
    end
  end
end
