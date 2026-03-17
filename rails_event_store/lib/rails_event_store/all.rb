# frozen_string_literal: true

require "ruby_event_store"
require_relative "async_handler_helpers"
require_relative "link_by_metadata"
require_relative "after_commit_async_dispatcher"
require_relative "active_job_scheduler"
require_relative "active_job_id_only_scheduler"
require_relative "client"
require_relative "json_client"
require_relative "version"
require_relative "railtie"
require_relative "browser"

module RailsEventStore
  DEPRECATED_CONSTANTS = {
    Event: RubyEventStore::Event,
    InMemoryRepository: RubyEventStore::InMemoryRepository,
    Subscriptions: RubyEventStore::Subscriptions,
    Projection: RubyEventStore::Projection,
    WrongExpectedEventVersion: RubyEventStore::WrongExpectedEventVersion,
    InvalidExpectedVersion: RubyEventStore::InvalidExpectedVersion,
    IncorrectStreamData: RubyEventStore::IncorrectStreamData,
    EventNotFound: RubyEventStore::EventNotFound,
    SubscriberNotExist: RubyEventStore::SubscriberNotExist,
    InvalidHandler: RubyEventStore::InvalidHandler,
    InvalidPageStart: RubyEventStore::InvalidPageStart,
    InvalidPageStop: RubyEventStore::InvalidPageStop,
    InvalidPageSize: RubyEventStore::InvalidPageSize,
    CorrelatedCommands: RubyEventStore::CorrelatedCommands,
    GLOBAL_STREAM: RubyEventStore::GLOBAL_STREAM,
    PAGE_SIZE: RubyEventStore::PAGE_SIZE,
    ImmediateAsyncDispatcher: RubyEventStore::ImmediateAsyncDispatcher,
  }.freeze

  def self.const_missing(name)
    if DEPRECATED_CONSTANTS.key?(name)
      warn <<~EOW
        RailsEventStore::#{name} is deprecated and will be removed in the next major release.

        Use RubyEventStore::#{name} instead.
      EOW
      DEPRECATED_CONSTANTS.fetch(name)
    else
      super
    end
  end
end
