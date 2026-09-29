# frozen_string_literal: true

require "logger"

module RubyEventStore
  module OutboxRelay
    # Independent process delivering outbox messages to async subscribers
    # (Client#subscribe_async).
    #
    # Each batch is claimed in a short transaction that leases the messages
    # (see Outbox), then delivered with no transaction open, so a slow or
    # failing subscriber never holds database locks, and a job enqueued by the
    # dispatcher is never deferred until after the message is gone. Delivered
    # messages are deleted in one statement per batch.
    #
    # A message whose event can't be read or deserialized, or whose subscriber
    # is not registered in this process, can never be delivered and goes to the
    # dead letters right away. A failed dispatch is retried according to the
    # RetryPolicy and dead-lettered once it gives up. Delivery is at least once:
    # a relay that crashes after dispatching, but before deleting, redelivers
    # once the lease runs out.
    class Relay
      # Outcome of one #process_batch call.
      BatchResult =
        Data.define(:claimed, :delivered, :retried, :dead) do
          def self.empty
            new(claimed: 0, delivered: 0, retried: 0, dead: 0)
          end
        end

      # Raised for a message whose event is not in the event store.
      class MissingEvent < StandardError; end

      # Raised for a message whose subscriber is not subscribed in this process.
      class UnknownSubscriber < StandardError; end

      Prepared = Data.define(:event, :record, :correlation_id)
      private_constant :Prepared

      BACKTRACE_LINES = 10
      private_constant :BACKTRACE_LINES

      # @param client [Object] the application's Client, extended with
      #   ClientExtension; async subscriptions, the outbox, the mapper and
      #   the event store are all read from it
      # @param batch_size [Integer] how many messages to claim per batch
      # @param poll_interval [Numeric] how long to sleep when nothing was due
      # @param lease_duration [Numeric] seconds a claimed message stays hidden
      #   from other relays; must comfortably exceed the time to deliver a batch
      # @param retry_policy [RetryPolicy]
      # @param clock [#call] returns the current time
      # @param signals [#trap] where the shutdown handlers are installed
      # @param logger [Logger]
      def initialize(
        client:,
        batch_size: 100,
        poll_interval: 1,
        lease_duration: 300,
        retry_policy: RetryPolicy.new,
        clock: -> { Time.now.utc },
        signals: Signal,
        logger: Logger.new($stdout)
      )
        @client = client
        @batch_size = batch_size
        @poll_interval = poll_interval
        @lease_duration = lease_duration
        @retry_policy = retry_policy
        @clock = clock
        @signals = signals
        @logger = logger
        @shutting_down = false
      end

      # Runs the relay loop until SIGINT/SIGTERM. Sleeps poll_interval whenever
      # no message was due.
      def run
        install_signal_handlers
        logger.info("Starting RubyEventStore::OutboxRelay")

        until @shutting_down
          result = process_batch_safely
          sleep(poll_interval) if result.claimed.zero?
        end

        logger.info("Gracefully shutting down")
      end

      # Claims and delivers a single batch of due messages.
      #
      # @return [BatchResult]
      def process_batch
        now = clock.call
        messages = outbox.claim(batch_size, now: now, lease_until: now + lease_duration)
        return BatchResult.empty if messages.empty?

        prepared = prepare_events(messages.map(&:event_id).uniq)
        outcomes = messages.group_by { |message| deliver(message, prepared.fetch(message.event_id)) }
        delivered = outcomes.fetch(:delivered, [])
        outbox.delete(delivered.map(&:outbox_id))

        BatchResult.new(
          claimed: messages.size,
          delivered: delivered.size,
          retried: outcomes.fetch(:retried, []).size,
          dead: outcomes.fetch(:dead, []).size,
        )
      end

      private

      attr_reader :client, :batch_size, :poll_interval, :lease_duration, :retry_policy, :clock, :signals, :logger

      def outbox
        client.outbox
      end

      def subscriptions
        client.async_subscriptions
      end

      def process_batch_safely
        process_batch
      rescue StandardError => e
        logger.error("Error while processing outbox batch: #{e.class}")
        logger.debug("Outbox batch error detail: #{e.message}\n#{Array(e.backtrace).first(BACKTRACE_LINES).join("\n")}")
        BatchResult.empty
      end

      def prepare_events(event_ids)
        events = read_events(event_ids)
        event_ids.to_h { |event_id| [event_id, prepare_event(event_id, events)] }
      end

      def read_events(event_ids)
        client.read.events(event_ids).to_h { |event| [event.event_id, event] }
      rescue StandardError
        event_ids.to_h { |event_id| [event_id, read_event(event_id)] }
      end

      def read_event(event_id)
        client.read.event(event_id)
      rescue StandardError => e
        e
      end

      def prepare_event(event_id, events)
        event = events[event_id]
        raise event if event.is_a?(StandardError)
        raise MissingEvent, "event #{event_id} not found" unless event
        Prepared.new(
          event: event,
          record: client.mapper.events_to_records([event]).first,
          correlation_id: event.metadata.fetch(:correlation_id),
        )
      rescue StandardError => e
        e
      end

      def deliver(message, prepared)
        subscriber = resolve_subscriber(message, prepared)
      rescue StandardError => e
        bury(message, e)
      else
        dispatch_or_retry(message, subscriber, prepared)
      end

      def resolve_subscriber(message, prepared)
        raise prepared if prepared.is_a?(StandardError)
        subscriptions.resolve(message.topic, message.subscriber) or
          raise UnknownSubscriber, "#{message.subscriber} is not subscribed to #{message.topic}"
      end

      def dispatch_or_retry(message, subscriber, prepared)
        dispatch(subscriber, prepared)
        :delivered
      rescue StandardError => e
        attempts = message.attempts + 1
        retry_policy.retry?(e, attempts) ? reschedule(message, attempts, e) : bury(message, e)
      end

      def dispatch(subscriber, prepared)
        client.with_metadata(correlation_id: prepared.correlation_id, causation_id: prepared.event.event_id) do
          subscriptions.dispatch(subscriber, prepared.event, prepared.record)
        end
      end

      def reschedule(message, attempts, error)
        next_attempt_at = retry_policy.next_attempt_at(attempts, clock.call)
        outbox.reschedule(message, attempts: attempts, next_attempt_at: next_attempt_at, error: error)
        logger.warn(
          "Outbox message #{message.outbox_id} (event #{message.event_id}, #{message.subscriber}) failed " \
            "attempt #{attempts}/#{retry_policy.max_attempts}, next at #{next_attempt_at.iso8601}: #{error.class}",
        )
        :retried
      end

      def bury(message, error)
        attempts = message.attempts + 1
        outbox.bury(message, attempts: attempts, error: error, now: clock.call)
        logger.error(
          "Outbox message #{message.outbox_id} (event #{message.event_id}, #{message.subscriber}) moved to dead letters " \
            "after #{attempts} attempt(s): #{error.class}",
        )
        :dead
      end

      def install_signal_handlers
        %w[INT TERM].each { |signal| chain_signal_handler(signal) }
      end

      def chain_signal_handler(signal)
        previous =
          signals.trap(signal) do |signo|
            @shutting_down = true
            previous.call(signo) if previous.respond_to?(:call)
          end
      end
    end
  end
end
