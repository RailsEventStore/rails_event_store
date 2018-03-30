require 'ruby_event_store'
require 'support/rspec_defaults'
require 'pry'

OrderCreated = Class.new(RubyEventStore::Event)
ProductAdded = Class.new(RubyEventStore::Event)
TestEvent = Class.new(RubyEventStore::Event)

RSpec.configure do |config|
  config.around(:each) do |example|
    Timeout.timeout(5, &example)
  end
end

module Subscribers
  class InvalidHandler
  end

  class ValidHandler
    def initialize
      @handled_events = []
    end
    attr_reader :handled_events

    def call(event)
      @handled_events << event
    end
  end
end

