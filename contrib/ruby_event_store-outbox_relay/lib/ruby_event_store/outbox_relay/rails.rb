# frozen_string_literal: true

require "rails_event_store"
require_relative "../outbox_relay"

module RubyEventStore
  module OutboxRelay
    # A RailsEventStore::Client with async subscriptions delivered through the
    # outbox, see ClientExtension. Requires rails_event_store, which this gem
    # doesn't depend on, so it is loaded on its own:
    #
    #   gem "ruby_event_store-outbox_relay", require: "ruby_event_store/outbox_relay/rails"
    class RailsClient < RailsEventStore::Client
      include ClientExtension
    end
  end
end
