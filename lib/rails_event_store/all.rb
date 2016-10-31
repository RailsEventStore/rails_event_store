require 'ruby_event_store'
require 'rails_event_store/repository'
require 'rails_event_store/client'
require 'rails_event_store/version'

module RailsEventStore
  Event                     = RubyEventStore::Event
  InMemoryRepository        = RubyEventStore::InMemoryRepository
  EventBroker               = RubyEventStore::PubSub::Broker
  Projection                = RubyEventStore::Projection
  WrongExpectedEventVersion = RubyEventStore::WrongExpectedEventVersion
  InvalidExpectedVersion    = RubyEventStore::InvalidExpectedVersion
  IncorrectStreamData       = RubyEventStore::IncorrectStreamData
  EventNotFound             = RubyEventStore::EventNotFound
  SubscriberNotExist        = RubyEventStore::SubscriberNotExist
  MethodNotDefined          = RubyEventStore::MethodNotDefined
  InvalidPageStart          = RubyEventStore::InvalidPageStart
  InvalidPageSize           = RubyEventStore::InvalidPageSize
  GLOBAL_STREAM             = RubyEventStore::GLOBAL_STREAM
  PAGE_SIZE                 = RubyEventStore::PAGE_SIZE
end
