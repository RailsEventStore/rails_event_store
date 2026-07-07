# frozen_string_literal: true

module RubyEventStore
  module Browser
    PAGE_SIZE = 20
    SERIALIZED_GLOBAL_STREAM_NAME = "all".freeze
  end
end

require_relative "browser/get_events_from_stream"
require_relative "browser/gem_source"
require_relative "browser/engine"
