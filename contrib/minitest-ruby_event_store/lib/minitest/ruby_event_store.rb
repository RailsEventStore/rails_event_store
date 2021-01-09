module Minitest
  module RubyEventStore
    class Error < StandardError; end
  end
end

require_relative "ruby_event_store/version"
require_relative "ruby_event_store/assertions"
