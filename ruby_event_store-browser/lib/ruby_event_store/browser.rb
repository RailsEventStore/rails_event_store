# frozen_string_literal: true

module RubyEventStore
  module Browser
    PAGE_SIZE = 20
    SERIALIZED_GLOBAL_STREAM_NAME = "all".freeze
    DEFAULT_RELATED_STREAMS_QUERY = ->(stream_name) { [] }
  end
end

require_relative "browser/get_event"
require_relative "browser/json_api_event"
require_relative "browser/json_api_stream"
require_relative "browser/get_events_from_stream"
require_relative "browser/get_stream"
require_relative "browser/urls"
require_relative "browser/gem_source"
require_relative "browser/router"
