# frozen_string_literal: true

require "ruby_event_store"
require "ruby_event_store/active_record"
require_relative "outbox_relay/version"
require_relative "outbox_relay/configuration"
require_relative "outbox_relay/client_extension"
require_relative "outbox_relay/event_repository_extension"
require_relative "outbox_relay/relay"
require_relative "outbox_relay/generators/migration_generator"

RubyEventStore::Client.include(RubyEventStore::OutboxRelay::ClientExtension)
RailsEventStore::Client.include(RubyEventStore::OutboxRelay::ClientExtension)
RubyEventStore::ActiveRecord::EventRepository.prepend(RubyEventStore::OutboxRelay::EventRepositoryExtension)
