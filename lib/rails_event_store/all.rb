require 'active_support/core_ext/class/attribute_accessors'
require 'ruby_event_store'
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
  CannotObtainLock          = RubyEventStore::CannotObtainLock
  Locker                    = RubyEventStore::Locker
  GLOBAL_STREAM             = RubyEventStore::GLOBAL_STREAM
  PAGE_SIZE                 = RubyEventStore::PAGE_SIZE

  mattr_reader :event_repository

  def self.event_repository=(event_repository)
    raise ArgumentError unless event_repository
    @@event_repository = event_repository
  end
end
