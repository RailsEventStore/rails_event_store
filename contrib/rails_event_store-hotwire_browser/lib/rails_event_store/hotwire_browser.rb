# frozen_string_literal: true

module RailsEventStore
  module HotwireBrowser
    PAGE_SIZE = 20
    SERIALIZED_GLOBAL_STREAM_NAME = "all".freeze
  end
end

require_relative "hotwire_browser/get_events_from_stream"
require_relative "hotwire_browser/gem_source"
require_relative "hotwire_browser/engine"
