require 'ruby_event_store'

module RailsEventStore
  GLOBAL_STREAM             = RubyEventStore::GLOBAL_STREAM
  PAGE_SIZE                 = RubyEventStore::PAGE_SIZE
  Event                     = RubyEventStore::Event
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
end

require 'rails_event_store/version'
require 'rails_event_store/repository'
require 'rails_event_store/client'
require 'rails_event_store/railtie' if defined?(Rails::Railtie)

# Use active_record adapter by default
RailsEventStore::Repository.adapter = :active_record
