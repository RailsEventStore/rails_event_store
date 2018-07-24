require 'ruby_event_store'
require 'rails_event_store/async_proxy_strategy'

module RailsEventStore
  Event                      = RubyEventStore::Event
  InMemoryRepository         = RubyEventStore::InMemoryRepository
  Subscriptions              = RubyEventStore::PubSub::Subscriptions
  Projection                 = RubyEventStore::Projection
  WrongExpectedEventVersion  = RubyEventStore::WrongExpectedEventVersion
  InvalidExpectedVersion     = RubyEventStore::InvalidExpectedVersion
  IncorrectStreamData        = RubyEventStore::IncorrectStreamData
  EventNotFound              = RubyEventStore::EventNotFound
  SubscriberNotExist         = RubyEventStore::SubscriberNotExist
  InvalidHandler             = RubyEventStore::InvalidHandler
  InvalidPageStart           = RubyEventStore::InvalidPageStart
  InvalidPageSize            = RubyEventStore::InvalidPageSize
  CorrelatedCommands         = RubyEventStore::CorrelatedCommands
  CorrelatedEvents           = RubyEventStore::CorrelatedEvents
  GLOBAL_STREAM              = RubyEventStore::GLOBAL_STREAM
  PAGE_SIZE                  = RubyEventStore::PAGE_SIZE
  AsyncProxyStrategy::Inline = RubyEventStore::AsyncProxyStrategy::Inline
  AsyncDispatcher            = RubyEventStore::AsyncDispatcher
end

require 'rails_event_store/active_job_dispatcher'
require 'rails_event_store/async_handler_helpers'
require 'rails_event_store/link_by_metadata'
require 'rails_event_store/client'
require 'rails_event_store/version'
require 'rails_event_store/railtie'
require 'rails_event_store/deprecations'
