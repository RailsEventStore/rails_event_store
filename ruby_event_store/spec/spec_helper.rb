require 'ruby_event_store'
require 'support/rspec_defaults'
require 'pry'

OrderCreated = Class.new(RubyEventStore::Event)
ProductAdded = Class.new(RubyEventStore::Event)