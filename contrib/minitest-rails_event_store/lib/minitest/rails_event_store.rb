module Minitest
  module RailsEventStore
    class Error < StandardError; end
  end
end

require_relative "rails_event_store/version"
require_relative "rails_event_store/assertions"
