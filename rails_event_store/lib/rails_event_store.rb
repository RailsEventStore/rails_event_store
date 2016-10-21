require 'ruby_event_store'
require 'rails_event_store_active_record'

module RailsEventStore
  Event               = RubyEventStore::Event
  InMemoryRepository  = RubyEventStore::InMemoryRepository
  EventBroker         = RubyEventStore::PubSub::Broker
  Projection          = RubyEventStore::Projection

  GLOBAL_STREAM       = RubyEventStore::GLOBAL_STREAM
  PAGE_SIZE           = RubyEventStore::PAGE_SIZE

  WrongExpectedEventVersion  = RubyEventStore::WrongExpectedEventVersion
  InvalidExpectedVersion     = RubyEventStore::InvalidExpectedVersion
  IncorrectStreamData        = RubyEventStore::IncorrectStreamData
  EventNotFound              = RubyEventStore::EventNotFound
  SubscriberNotExist         = RubyEventStore::SubscriberNotExist
  MethodNotDefined           = RubyEventStore::MethodNotDefined
  InvalidPageStart           = RubyEventStore::InvalidPageStart
  InvalidPageSize            = RubyEventStore::InvalidPageSize
end

require 'rails_event_store/version'
require 'rails_event_store/client'
require 'rails_event_store/railtie' if defined?(Rails::Railtie)
