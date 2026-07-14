# frozen_string_literal: true

module RailsEventStore
  module HotwireBrowser
    class AssetsController < ApplicationController
      CSS = File.expand_path("../../../../public/rails_event_store_hotwire_browser.css", __dir__)

      def stylesheet
        send_file CSS, type: "text/css", disposition: "inline"
      end
    end
  end
end
