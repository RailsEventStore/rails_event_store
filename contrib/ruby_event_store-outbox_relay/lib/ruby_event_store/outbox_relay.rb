# frozen_string_literal: true

require "ruby_event_store"
require "ruby_event_store/active_record"
require_relative "outbox_relay/version"
require_relative "outbox_relay/configuration"
require_relative "outbox_relay/async_subscriptions"
require_relative "outbox_relay/active_job_dispatcher"
require_relative "outbox_relay/outbox"
require_relative "outbox_relay/retry_policy"
require_relative "outbox_relay/dead_letters"
require_relative "outbox_relay/client_extension"
require_relative "outbox_relay/relay"
require_relative "outbox_relay/generators/migration_generator"
require_relative "outbox_relay/railtie"

RubyEventStore::Client.include(RubyEventStore::OutboxRelay::ClientExtension)
RailsEventStore::Client.include(RubyEventStore::OutboxRelay::ClientExtension)
