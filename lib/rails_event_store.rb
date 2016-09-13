require 'ruby_event_store'

module RailsEventStore
  Event           = RubyEventStore::Event
  EventBroker     = RubyEventStore::PubSub::Broker
  EventRepository = RubyEventStore::InMemoryRepository
  Projection      = RubyEventStore::Projection
end

require 'rails_event_store/version'
require 'rails_event_store/event_repository'
require 'rails_event_store/client'
require 'rails_event_store/constants'
require 'rails_event_store/railtie' if defined?(Rails::Railtie)
