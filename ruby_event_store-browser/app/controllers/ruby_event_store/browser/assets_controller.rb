# frozen_string_literal: true

module RubyEventStore
  module Browser
    class AssetsController < ApplicationController
      CSS = File.expand_path("../../../../public/ruby_event_store_browser.css", __dir__)

      def stylesheet
        send_file CSS, type: "text/css", disposition: "inline"
      end
    end
  end
end
