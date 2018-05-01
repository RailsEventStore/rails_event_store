module RailsEventStore
  module Browser
    PAGE_SIZE = 20
    SERIALIZED_GLOBAL_STREAM_NAME = 'all'.freeze
  end
end

require 'rails_event_store/browser/engine'
