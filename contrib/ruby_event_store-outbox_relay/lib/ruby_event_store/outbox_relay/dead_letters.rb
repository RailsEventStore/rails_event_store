# frozen_string_literal: true

module RubyEventStore
  module OutboxRelay
    # Inspects and resolves deliveries the relay gave up on.
    #
    # Requeueing moves a dead letter back to the outbox as a fresh message, with
    # its attempts reset, in one transaction together with removing the dead
    # letter.
    class DeadLetters
      include Enumerable

      BATCH_SIZE = 1000

      # @param message_klass [Class] ActiveRecord model of event_store_outbox_messages
      # @param dead_letter_klass [Class] ActiveRecord model of event_store_outbox_dead_letters
      # @param clock [#call] returns the current time
      def initialize(message_klass: Message, dead_letter_klass: DeadLetter, clock: -> { Time.now.utc })
        @message_klass = message_klass
        @dead_letter_klass = dead_letter_klass
        @clock = clock
      end

      # @yieldparam dead_letter [DeadLetter] oldest first
      def each(&block)
        dead_letter_klass.find_each(&block)
      end

      # @return [Integer]
      def count
        dead_letter_klass.count
      end

      # @param id [Integer]
      # @raise [ActiveRecord::RecordNotFound]
      def requeue(id)
        raise_not_found(id) if move(dead_letter_klass.where(id: id)).zero?
      end

      # @param topic [String, nil] only dead letters of this topic
      # @param subscriber [String, nil] only dead letters of this subscriber
      # @return [Integer] number of requeued dead letters
      def requeue_all(topic: nil, subscriber: nil)
        scope = dead_letter_klass.where({ topic: topic, subscriber: subscriber }.compact).order(:id).limit(BATCH_SIZE)
        requeued = 0
        while (moved = move(scope)).positive?
          requeued += moved
        end
        requeued
      end

      # @param id [Integer]
      # @raise [ActiveRecord::RecordNotFound]
      def discard(id)
        raise_not_found(id) if dead_letter_klass.where(id: id).delete_all.zero?
      end

      private

      attr_reader :message_klass, :dead_letter_klass, :clock

      def move(scope)
        dead_letter_klass.transaction(requires_new: true) do
          now = clock.call
          rows = scope.lock.pluck(:event_id, :topic, :subscriber)
          message_klass.insert_all!(
            rows.map do |event_id, topic, subscriber|
              { event_id: event_id, topic: topic, subscriber: subscriber, next_attempt_at: now, created_at: now }
            end,
          )
          scope.delete_all
        end
      end

      def raise_not_found(id)
        raise ::ActiveRecord::RecordNotFound.new("Couldn't find dead letter with id=#{id}", dead_letter_klass.name, "id", id)
      end
    end
  end
end
