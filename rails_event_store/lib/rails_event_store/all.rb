require 'active_support/core_ext/class/attribute_accessors'
require 'ruby_event_store'
require 'rails_event_store/client'
require 'rails_event_store/version'
require 'rails_event_store/railtie'
require 'rails_event_store/deprecations'
require 'rails_event_store/active_job_dispatcher'

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
  InvalidHandler            = RubyEventStore::InvalidHandler
  InvalidPageStart          = RubyEventStore::InvalidPageStart
  InvalidPageSize           = RubyEventStore::InvalidPageSize
  PAGE_SIZE                 = RubyEventStore::PAGE_SIZE

  mattr_reader :event_repository

  def self.event_repository=(event_repository)
    raise ArgumentError unless event_repository
    @@event_repository = event_repository
  end
end
