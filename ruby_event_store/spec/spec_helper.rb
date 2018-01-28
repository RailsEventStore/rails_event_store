require 'ruby_event_store'
require 'support/rspec_defaults'


OrderCreated = Class.new(RubyEventStore::Event)
ProductAdded = Class.new(RubyEventStore::Event)
