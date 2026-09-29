# frozen_string_literal: true

module RubyEventStore
  module OutboxRelay
    # A RubyEventStore::Client with async subscriptions delivered through the
    # outbox, see ClientExtension.
    class Client < RubyEventStore::Client
      include ClientExtension
    end
  end
end
