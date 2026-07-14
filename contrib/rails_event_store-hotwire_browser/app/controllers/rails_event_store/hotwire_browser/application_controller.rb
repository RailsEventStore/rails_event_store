# frozen_string_literal: true

module RailsEventStore
  module HotwireBrowser
    class ApplicationController < ActionController::Base
      helper_method :asset_url

      rescue_from RubyEventStore::EventNotFound do
        render "rails_event_store/hotwire_browser/not_found", status: :not_found
      end

      private

      def event_store
        Rails.configuration.event_store
      end

      def asset_url(name, local_path)
        source = GemSource.new($LOAD_PATH)
        source.from_git? ? "https://cdn.railseventstore.org/#{source.version}/#{name}" : local_path
      end
    end
  end
end
