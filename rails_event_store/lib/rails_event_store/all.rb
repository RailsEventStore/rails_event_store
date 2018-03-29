require 'ruby_event_store'
require 'rails_event_store/active_job_dispatcher'
require 'rails_event_store/client'
require 'rails_event_store/version'
require 'rails_event_store/railtie'
require 'rails_event_store/deprecations'

module RailsEventStore
  Event                     = RubyEventStore::Event
  Repository                = RubyEventStore::Repository
  InMemoryRepository        = RubyEventStore::InMemoryRepository
  EventBroker               = RubyEventStore::PubSub::Broker
  Projection                = RubyEventStore::Projection
  WrongExpectedEventVersion = RubyEventStore::WrongExpectedEventVersion
  InvalidExpectedVersion    = RubyEventStore::InvalidExpectedVersion
  IncorrectStreamData       = RubyEventStore::IncorrectStreamData
  EventNotFound             = RubyEventStore::EventNotFound
  SubscriberNotExist        = RubyEventStore::SubscriberNotExist
  InvalidHandler            = RubyEventStore::InvalidHandler
  InvalidPageStart          = RubyEventStore::InvalidPageStart
  InvalidPageSize           = RubyEventStore::InvalidPageSize
  GLOBAL_STREAM             = RubyEventStore::GLOBAL_STREAM
  PAGE_SIZE                 = RubyEventStore::PAGE_SIZE
end