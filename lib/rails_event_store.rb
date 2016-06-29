require 'ruby_event_store'
require 'rails_event_store_active_record'

module RailsEventStore
  Event               = RubyEventStore::Event
  InMemoryRepository  = RubyEventStore::InMemoryRepository
  EventBroker         = RubyEventStore::PubSub::Broker
  Projection          = RubyEventStore::Projection
end

require 'rails_event_store/version'
require 'rails_event_store/client'
require 'rails_event_store/constants'
require 'rails_event_store/railtie' if defined?(Rails::Railtie)
