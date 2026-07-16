# frozen_string_literal: true

module RubyEventStore
  module OutboxRelay
    # Makes RubyEventStore::ActiveRecord::EventRepository write every event with
    # published_at: nil, in the same INSERT that persists it -- without modifying
    # ruby_event_store-active_record itself. Prepended at gem-load time (see
    # ruby_event_store/outbox_relay.rb), together with ClientExtension, so the client
    # and the repository are extended consistently. Every event may have async
    # subscribers (see ClientExtension), so there is no toggle: the write and the
    # "needs delivery" intent are atomic for every event, unconditionally.
    module EventRepositoryExtension
      # Public on purpose -- ClientExtension's default_async_broker reuses this to
      # build a scheduler that serializes the same way the repository does.
      attr_reader :serializer

      private

      def insert_hash(record, serialized_record)
        super.tap { |hash| hash[:published_at] = nil }
      end
    end
  end
end
