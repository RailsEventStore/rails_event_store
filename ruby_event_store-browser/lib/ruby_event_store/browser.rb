module RubyEventStore
  module Browser
    PAGE_SIZE = 20
    SERIALIZED_GLOBAL_STREAM_NAME = 'all'.freeze
  end
end

require_relative 'browser/event'
require_relative 'browser/json_api_event'
require_relative 'browser/stream'
