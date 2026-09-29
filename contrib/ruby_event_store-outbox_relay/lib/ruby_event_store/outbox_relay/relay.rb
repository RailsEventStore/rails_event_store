# frozen_string_literal: true

require "logger"
require "active_support/notifications"

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
    # A failed delivery is retried according to the RetryPolicy and
    # dead-lettered once it gives up. That goes as well for a message whose event
    # can't be read or deserialized (MissingEvent, or the error of the mapper), or
    # whose subscriber is not registered in this process (UnknownSubscriber): each
    # can come right when a deploy has rolled out to the relay. List the ones that
    # can't in the RetryPolicy's +permanent_errors+ to dead-letter them at once.
    # The exception is a failure of the database while reading the events: it
    # says nothing about any message, so it fails the whole batch, whose messages
    # stay for the next attempt once their lease runs out.
    #
    # Delivery is at least once: a relay that crashes after dispatching, but
    # before deleting, redelivers once the lease runs out.
    #
    # It reports through +instrumentation+ (ActiveSupport::Notifications by
    # default), under names ending in ".outbox_relay.ruby_event_store":
    #
    # * +process_batch+, around each batch, with the counts of BatchResult;
    # * +message_failed+, for each message that failed to be delivered, with
    #   +outbox_id+, +event_id+, +topic+, +subscriber+, +attempts+, +error_class+
    #   and +outcome+ (+:retried+ or +:dead+). Never the error's message, which can
    #   echo event data;
    # * +stats+, every +stats_interval+ seconds, with the fields of Outbox::Stats.
    class Relay
      # Outcome of one #process_batch call. +unrecorded+ counts the messages whose
      # failure could not be recorded, which stay in the outbox untouched and come
      # back once their lease runs out.
      BatchResult =
        Data.define(:claimed, :delivered, :retried, :dead, :unrecorded) do
          def self.empty
            new(claimed: 0, delivered: 0, retried: 0, dead: 0, unrecorded: 0)
          end
        end

      # Raised for a message whose event is not in the event store. It is retried like
      # any other failure, unless the RetryPolicy lists it as permanent.
      class MissingEvent < StandardError; end

      # Raised for a message whose subscriber is not subscribed in this process. It is
      # retried like any other failure, unless the RetryPolicy lists it as permanent.
      class UnknownSubscriber < StandardError; end

      Prepared = Data.define(:event, :record, :correlation_id)
      Pending = Data.define(:message, :subscriber, :prepared)
      private_constant :Prepared, :Pending

      BACKTRACE_LINES = 10
      EVENT_NAMESPACE = "outbox_relay.ruby_event_store"
      private_constant :BACKTRACE_LINES, :EVENT_NAMESPACE

      # @param client [Object] the application's Client, extended with
      #   ClientExtension (an OutboxRelay::Client or RailsClient); async
      #   subscriptions, the outbox, the mapper and the event store are all read
      #   from it. In the relay process, use the very client of the application,
      #   so both share one list of subscribers
      # @param batch_size [Integer] how many messages to claim per batch
      # @param poll_interval [Numeric] how long to sleep when nothing was due
      # @param lease_duration [Numeric] seconds a claimed message stays hidden
      #   from other relays; must comfortably exceed the time to deliver a batch
      # @param retry_policy [RetryPolicy]
      # @param clock [#call] returns the current time
      # @param signals [#trap] where the shutdown handlers are installed
      # @param instrumentation [#instrument] receives the notifications listed above
      # @param stats_interval [Numeric, nil] seconds between +stats+ notifications;
      #   nil turns them off
      # @param logger [Logger]
      # @raise [ArgumentError] when the client isn't extended with ClientExtension
      def initialize(
        client:,
        batch_size: 100,
        poll_interval: 1,
        lease_duration: 300,
        retry_policy: RetryPolicy.new,
        clock: -> { Time.now.utc },
        signals: Signal,
        instrumentation: ActiveSupport::Notifications,
        stats_interval: 30,
        logger: Logger.new($stdout)
      )
        unless client.respond_to?(:outbox) && client.respond_to?(:async_subscriptions)
          raise ArgumentError,
                "client must be extended with RubyEventStore::OutboxRelay::ClientExtension, " \
                  "e.g. an OutboxRelay::Client or a RailsClient, got #{client.class}"
        end
        @client = client
        @batch_size = batch_size
        @poll_interval = poll_interval
        @lease_duration = lease_duration
        @retry_policy = retry_policy
        @clock = clock
        @signals = signals
        @instrumentation = instrumentation
        @stats_interval = stats_interval
        @logger = logger
        @shutting_down = false
      end

      # Runs the relay loop until SIGINT/SIGTERM. Sleeps poll_interval whenever
      # no message was due.
      def run
        install_signal_handlers
        logger.info("Starting RubyEventStore::OutboxRelay")
        log_subscribers

        until @shutting_down
          result = process_batch_safely
          log_batch(result)
          publish_stats_if_due
          sleep(poll_interval) if result.claimed.zero?
        end

        logger.info("Gracefully shutting down")
      end

      # Claims and delivers a single batch of due messages.
      #
      # @return [BatchResult]
      def process_batch
        instrumentation.instrument("process_batch.#{EVENT_NAMESPACE}", {}) do |payload|
          deliver_batch.tap { |result| payload.merge!(result.to_h) }
        end
      end

      private

      attr_reader :client,
                  :batch_size,
                  :poll_interval,
                  :lease_duration,
                  :retry_policy,
                  :clock,
                  :signals,
                  :instrumentation,
                  :stats_interval,
                  :logger

      def deliver_batch
        now = clock.call
        messages = outbox.claim(batch_size, now: now, lease_until: now + lease_duration)
        return BatchResult.empty if messages.empty?

        outcomes = deliver_all(messages, prepare_events(messages.map(&:event_id).uniq))
        delivered = outcomes.fetch(:delivered, [])
        outbox.delete(delivered.map(&:outbox_id))

        BatchResult.new(
          claimed: messages.size,
          delivered: delivered.size,
          retried: outcomes.fetch(:retried, []).size,
          dead: outcomes.fetch(:dead, []).size,
          unrecorded: outcomes.fetch(:unrecorded, []).size,
        )
      end

      def outbox
        client.outbox
      end

      def subscriptions
        client.async_subscriptions
      end

      def log_subscribers
        registered = subscriptions.to_h
        if registered.empty?
          logger.warn("No async subscribers registered: every message will fail as unknown, and be retried until it is dead-lettered")
        else
          registered.each { |topic, names| logger.info("Async subscribers of #{topic}: #{names.join(", ")}") }
        end
      end

      def log_batch(result)
        return if result.claimed.zero?
        logger.debug(
          "Batch: claimed=#{result.claimed} delivered=#{result.delivered} retried=#{result.retried} dead=#{result.dead} " \
            "unrecorded=#{result.unrecorded}",
        )
      end

      def publish_stats_if_due
        return unless stats_interval
        now = clock.call
        return if @stats_at && now - @stats_at < stats_interval
        @stats_at = now
        instrumentation.instrument("stats.#{EVENT_NAMESPACE}", outbox.stats(now: now).to_h)
      rescue StandardError => e
        logger.error("Error while collecting outbox stats: #{e.class}")
      end

      def instrument_failure(message, attempts, error, outcome)
        instrumentation.instrument(
          "message_failed.#{EVENT_NAMESPACE}",
          outbox_id: message.outbox_id,
          event_id: message.event_id,
          topic: message.topic,
          subscriber: message.subscriber,
          attempts: attempts,
          error_class: error.class.to_s,
          outcome: outcome,
        )
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
      rescue ::ActiveRecord::ActiveRecordError
        raise
      rescue StandardError
        event_ids.to_h { |event_id| [event_id, read_event(event_id)] }
      end

      def read_event(event_id)
        client.read.event(event_id)
      rescue ::ActiveRecord::ActiveRecordError
        raise
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

      def deliver_all(messages, prepared)
        outcomes = {}
        pending = []
        messages.each do |message|
          prepared_event = prepared.fetch(message.event_id)
          pending << Pending.new(message, resolve_subscriber(message, prepared_event), prepared_event)
        rescue StandardError => e
          outcomes[message] = record_failure(message) { fail_dispatch(message, e) }
        end
        pending.zip(dispatch_all(pending)) do |item, error|
          outcomes[item.message] = error ? record_failure(item.message) { fail_dispatch(item.message, error) } : :delivered
        end
        messages.group_by { |message| outcomes.fetch(message) }
      end

      def resolve_subscriber(message, prepared)
        raise prepared if prepared.is_a?(StandardError)
        subscriptions.resolve(message.topic, message.subscriber) or
          raise UnknownSubscriber, "#{message.subscriber} is not subscribed to #{message.topic}"
      end

      def dispatch_all(pending)
        return dispatch_each(pending) unless subscriptions.bulk? && pending.any?
        dispatch_in_bulk(pending)
      end

      def dispatch_in_bulk(pending)
        subscriptions.dispatch_all(
          pending.map do |item|
            AsyncSubscriptions::Delivery.new(subscriber: item.subscriber, event: item.prepared.event, record: item.prepared.record)
          end,
        )
      rescue StandardError
        dispatch_each(pending)
      end

      def dispatch_each(pending)
        pending.map { |item| dispatch(item.subscriber, item.prepared) }
      end

      def dispatch(subscriber, prepared)
        client.with_metadata(correlation_id: prepared.correlation_id, causation_id: prepared.event.event_id) do
          subscriptions.dispatch(subscriber, prepared.event, prepared.record)
        end
        nil
      rescue StandardError => e
        e
      end

      def record_failure(message)
        yield
      rescue StandardError => e
        logger.error("Could not record the failure of outbox message #{message.outbox_id}: #{e.class}")
        :unrecorded
      end

      def fail_dispatch(message, error)
        attempts = message.attempts + 1
        retry_policy.retry?(error, attempts) ? reschedule(message, attempts, error) : bury(message, error)
      end

      def reschedule(message, attempts, error)
        next_attempt_at = retry_policy.next_attempt_at(attempts, clock.call)
        outbox.reschedule(message, attempts: attempts, next_attempt_at: next_attempt_at, error: error)
        logger.warn(
          "Outbox message #{message.outbox_id} (event #{message.event_id}, #{message.subscriber}) failed " \
            "attempt #{attempts}/#{retry_policy.max_attempts}, next at #{next_attempt_at.iso8601}: #{error.class}",
        )
        instrument_failure(message, attempts, error, :retried)
        :retried
      end

      def bury(message, error)
        attempts = message.attempts + 1
        if outbox.bury(message, attempts: attempts, error: error, now: clock.call)
          logger.error(
            "Outbox message #{message.outbox_id} (event #{message.event_id}, #{message.subscriber}) moved to dead letters " \
              "after #{attempts} attempt(s): #{error.class}",
          )
          instrument_failure(message, attempts, error, :dead)
        end
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
