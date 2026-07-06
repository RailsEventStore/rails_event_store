# frozen_string_literal: true

module RubyEventStore
  module Browser
    class ApplicationController < ActionController::Base
      rescue_from RubyEventStore::EventNotFound do
        head :not_found
      end

      private

      def event_store
        Rails.configuration.event_store
      end
    end
  end
end
