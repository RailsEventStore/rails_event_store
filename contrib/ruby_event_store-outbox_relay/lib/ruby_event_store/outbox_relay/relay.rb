# frozen_string_literal: true

require "logger"

module RubyEventStore
  module OutboxRelay
    # Independent process that dispatches events to async subscribers
    # (Client#subscribe_async) via the client's async_broker.
    #
    # The relay never writes anything to the database other than a single
    # published_at UPDATE -- it does not append, it does not call publish.
    # Only: fetch a batch -> deserialize -> call the broker -> UPDATE.
    class Relay
      # @param client [Object] the application's Client, extended with
      #   RubyEventStore::OutboxRelay::ClientExtension -- broker, mapper, and
      #   serializer are all read from it (client.async_broker, client.mapper,
      #   client.repository.serializer)
      # @param event_klass [Class] the ActiveRecord model backed by event_store_events.
      #   Defaults via Module#const_get rather than a direct constant reference,
      #   since RubyEventStore::ActiveRecord::Event is a private_constant and Relay
      #   is not lexically nested inside RubyEventStore::ActiveRecord.
      # @param batch_size [Integer] how many events to fetch per batch
      # @param poll_interval [Numeric] how long to sleep after an empty batch
      # @param logger [Logger]
      def initialize(
        client:,
        event_klass: RubyEventStore::ActiveRecord.const_get(:Event),
        batch_size: 100,
        poll_interval: 1,
        logger: Logger.new($stdout)
      )
        @client = client
        @event_klass = event_klass
        @batch_size = batch_size
        @poll_interval = poll_interval
        @logger = logger
        @shutting_down = false
      end

      # Runs the relay loop until SIGINT/SIGTERM. Sleeps poll_interval after an
      # empty batch.
      def run
        install_signal_handlers
        logger.info("Starting RubyEventStore::OutboxRelay")

        until @shutting_down
          processed = process_batch_safely
          sleep(poll_interval) if processed.zero?
        end

        logger.info("Gracefully shutting down")
      end

      # Fetches and processes a single batch of pending events. Public because it
      # is called directly from tests. Returns the number of events successfully
      # processed (which can be less than the batch size -- see #process_row).
      #
      # The batch is fetched with SELECT ... FOR UPDATE SKIP LOCKED inside one SQL
      # transaction, held for the duration of the whole batch so no other relay
      # instance can grab the same rows. Each row is then deserialized, dispatched,
      # and marked published in its own nested transaction (#process_row), so one
      # event failing doesn't roll back or block the rest of the batch.
      # @return [Integer]
      def process_batch
        ensure_skip_json_serialization!

        event_klass.transaction do
          rows = fetch_batch
          rows.count { |row| process_row(row) }
        end
      end

      private

      attr_reader :client, :event_klass, :batch_size, :poll_interval, :logger

      def broker
        client.async_broker
      end

      def mapper
        client.mapper
      end

      def serializer
        client.repository.serializer
      end

      # RubyEventStore::ActiveRecord::EventRepository only mixes
      # SkipJsonSerialization into event_klass as a side effect of the app
      # process using the repository (#model_klasses, called from e.g.
      # #append_to_stream). The relay runs in its own process and never calls
      # the repository, so without this, ActiveRecord auto-deserializes a
      # json/jsonb data or metadata column into a Hash on read, which then
      # fails to (re)deserialize through the configured serializer.
      #
      # Mirrors EventRepository#model_klasses: include unconditionally for any
      # non-NULL serializer (harmless for non-json columns -- the module only
      # affects json/jsonb cast types) rather than checking column types first,
      # since inspecting a column's type resolves and caches the class's
      # attribute types, and including the module afterwards would then be too
      # late to affect that already-cached type.
      def ensure_skip_json_serialization!
        return if @skip_json_serialization_ensured
        @skip_json_serialization_ensured = true
        return if serializer == RubyEventStore::NULL

        event_klass.include(RubyEventStore::ActiveRecord.const_get(:SkipJsonSerialization))
      end

      def process_batch_safely
        process_batch
      rescue StandardError => e
        logger.error("Error while processing outbox batch: #{e.class}: #{e.message}")
        0
      end

      def fetch_batch
        scope = event_klass.where(published_at: nil).order(:id).limit(batch_size)
        scope = scope.lock(lock_clause) if lock_clause
        scope.to_a
      end

      # Deserializes, dispatches, and marks a single row published, inside its own
      # nested transaction (SAVEPOINT) so a failure here only rolls back this row,
      # not the rest of the batch. Returns true on success; on any StandardError
      # (bad data, a raising subscriber, a missing correlation_id, ...) it logs the
      # error, leaves published_at NULL for retry on a later batch, and returns
      # false.
      def process_row(row)
        event_klass.transaction(requires_new: true) do
          record = to_record(row)
          event = mapper.records_to_events([record]).first
          dispatch(event, record)
          event_klass.where(id: row.id).update_all(published_at: Time.now.utc)
        end
        true
      rescue StandardError => e
        logger.error("Error while processing outbox event #{row.event_id} (#{row.event_type}): #{e.class}: #{e.message}")
        false
      end

      def lock_clause
        "FOR UPDATE SKIP LOCKED" if event_klass.connection.adapter_name.match?(/postgres|mysql/i)
      end

      def dispatch(event, record)
        client.with_metadata(
          correlation_id: event.metadata.fetch(:correlation_id),
          causation_id: event.event_id,
        ) do
          if broker.public_method(:call).arity == 3
            broker.call(event.event_type, event, record)
          else
            warn <<~EOW
              Message broker shall support topics.
              Topic WILL BE IGNORED in the current broker.
              Modify the broker implementation to pass topic as an argument to broker.call method.
            EOW
            broker.call(event, record)
          end
        end
      end

      def to_record(row)
        RubyEventStore::SerializedRecord.new(
          event_id: row.event_id,
          metadata: row.metadata,
          data: row.data,
          event_type: row.event_type,
          timestamp: row.created_at.iso8601(RubyEventStore::TIMESTAMP_PRECISION),
          valid_at: (row.valid_at || row.created_at).iso8601(RubyEventStore::TIMESTAMP_PRECISION),
        ).deserialize(serializer)
      end

      def install_signal_handlers
        Signal.trap("INT") { @shutting_down = true }
        Signal.trap("TERM") { @shutting_down = true }
      end
    end
  end
end
