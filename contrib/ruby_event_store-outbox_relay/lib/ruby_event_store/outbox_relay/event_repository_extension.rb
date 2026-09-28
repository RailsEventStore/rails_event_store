# frozen_string_literal: true

module RubyEventStore
  module OutboxRelay
    # Makes RubyEventStore::ActiveRecord::EventRepository write every event with
    # published_at: nil, in the same INSERT that persists it -- without modifying
    # ruby_event_store-active_record itself. Prepended at gem-load time (see
    # ruby_event_store/outbox_relay.rb), together with ClientExtension, so the client
    # and the repository are extended consistently. Every event may have async
    # subscribers (see ClientExtension), so the write and the "needs delivery"
    # intent are atomic for every event -- except inside WithoutRelay.call, which
    # ClientExtension's #append opens to honor #append's own documented contract
    # of not notifying any subscribed handlers, sync or async.
    module EventRepositoryExtension
      # Public on purpose -- ClientExtension's default_async_broker reuses this to
      # build a scheduler that serializes the same way the repository does.
      attr_reader :serializer

      private

      def insert_hash(record, serialized_record)
        super.tap { |hash| hash[:published_at] = WithoutRelay.active? ? Time.now.utc : nil }
      end
    end
  end
end
