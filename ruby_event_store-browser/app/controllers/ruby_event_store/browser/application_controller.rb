# frozen_string_literal: true

module RubyEventStore
  module Browser
    class ApplicationController < ActionController::Base
      helper_method :asset_url

      rescue_from RubyEventStore::EventNotFound do
        head :not_found
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
