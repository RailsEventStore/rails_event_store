# frozen_string_literal: true

module RubyEventStore
  module OutboxRelay
    # A pending delivery of one event to one async subscriber.
    class Message < ::ActiveRecord::Base
      self.table_name = "event_store_outbox_messages"
    end

    # A delivery that exhausted its attempts or can never succeed.
    class DeadLetter < ::ActiveRecord::Base
      self.table_name = "event_store_outbox_dead_letters"
    end

    # All reads and writes of the outbox tables.
    #
    # A message is due when next_attempt_at <= now. Claiming a message moves its
    # next_attempt_at to the end of a lease, so a relay that crashes mid-batch
    # releases its messages simply by the lease running out.
    class Outbox
      MESSAGE_LIMIT = 1000
      BACKTRACE_LINES = 20

      # A claimed message, detached from the database.
      Entry = Data.define(:outbox_id, :event_id, :topic, :subscriber, :attempts, :created_at)

      # @param message_klass [Class] ActiveRecord model of event_store_outbox_messages
      # @param dead_letter_klass [Class] ActiveRecord model of event_store_outbox_dead_letters
      def initialize(message_klass: Message, dead_letter_klass: DeadLetter)
        @message_klass = message_klass
        @dead_letter_klass = dead_letter_klass
      end

      # Runs the block, which persists the records, and inserts one message per
      # (record, async subscriber of its topic) in the same transaction, so the
      # events and their pending deliveries are committed or rolled back
      # together. When no record has an async subscriber, the block runs alone,
      # without opening a transaction.
      #
      # @param records [Array<RubyEventStore::Record>]
      # @param topic [String, nil] overrides each record's event_type as the topic
      # @param subscriptions [AsyncSubscriptions]
      # @param now [Time]
      # @yield persists the records
      # @return the block's result
      def append(records, topic:, subscriptions:, now:)
        rows = message_rows(records, topic, subscriptions, now)
        return yield if rows.empty?

        transaction { yield.tap { message_klass.insert_all!(rows) } }
      end

      # Locks up to batch_size due messages, oldest first, skipping ones another
      # relay holds, and leases them until lease_until.
      #
      # @return [Array<Entry>]
      def claim(batch_size, now:, lease_until:)
        transaction do
          entries = due(batch_size, now).map { |message| entry_for(message) }
          message_klass.where(id: entries.map(&:outbox_id)).update_all(next_attempt_at: lease_until) unless entries.empty?
          entries
        end
      end

      # @param ids [Array<Integer>]
      def delete(ids)
        message_klass.where(id: ids).delete_all unless ids.empty?
      end

      # Records a failed attempt and schedules the next one.
      #
      # @param message [Entry]
      def reschedule(message, attempts:, next_attempt_at:, error:)
        message_klass.where(id: message.outbox_id).update_all(
          attempts: attempts,
          next_attempt_at: next_attempt_at,
          last_error: error_summary(error),
        )
      end

      # Moves a message to the dead letters. Does nothing when the message is
      # already gone, e.g. delivered by another relay after this one's lease ran out.
      #
      # @param message [Entry]
      # @return [Boolean] whether the message was moved
      def bury(message, attempts:, error:, now:)
        transaction do
          moved = message_klass.where(id: message.outbox_id).delete_all.positive?
          dead_letter_klass.insert!(dead_letter_row(message, attempts, error, now)) if moved
          moved
        end
      end

      private

      attr_reader :message_klass, :dead_letter_klass

      def transaction(&block)
        message_klass.transaction(requires_new: true, &block)
      end

      def message_rows(records, topic, subscriptions, now)
        records.flat_map do |record|
          message_topic = topic || record.event_type
          subscriptions
            .names_for(message_topic)
            .map do |subscriber|
              {
                event_id: record.event_id,
                topic: message_topic,
                subscriber: subscriber,
                next_attempt_at: now,
                created_at: now,
              }
            end
        end
      end

      def entry_for(message)
        Entry.new(
          outbox_id: message.id,
          event_id: message.event_id,
          topic: message.topic,
          subscriber: message.subscriber,
          attempts: message.attempts,
          created_at: message.created_at,
        )
      end

      def due(batch_size, now)
        message_klass
          .select(:id, :event_id, :topic, :subscriber, :attempts, :created_at)
          .where(next_attempt_at: ..now)
          .order(:next_attempt_at, :id)
          .limit(batch_size)
          .lock("FOR UPDATE SKIP LOCKED")
      end

      def dead_letter_row(message, attempts, error, now)
        {
          event_id: message.event_id,
          topic: message.topic,
          subscriber: message.subscriber,
          attempts: attempts,
          error_class: error.class.name,
          error_message: truncate(error.message),
          backtrace: Array(error.backtrace).first(BACKTRACE_LINES).join("\n"),
          first_enqueued_at: message.created_at,
          dead_at: now,
        }
      end

      def error_summary(error)
        truncate("#{error.class}: #{error.message}")
      end

      def truncate(text)
        text[0, MESSAGE_LIMIT]
      end
    end
  end
end
