require 'ruby_event_store'
require 'support/rspec_defaults'
require 'support/mutant_timeout'
require 'pry'
require_relative 'mappers/events_pb.rb'

OrderCreated = Class.new(RubyEventStore::Event)
ProductAdded = Class.new(RubyEventStore::Event)
TestEvent = Class.new(RubyEventStore::Event)

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

