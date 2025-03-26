# frozen_string_literal: true

module RubyEventStore
  module Outbox
    class Runner
      def initialize(consumer, configuration, logger:)
        @consumer = consumer
        @logger = logger
        @sleep_on_empty = configuration.sleep_on_empty
        @split_keys = configuration.split_keys
        @locking = configuration.locking
        @gracefully_shutting_down = false
        prepare_traps
      end

      def run
        logger.info("Initiated RubyEventStore::Outbox v#{VERSION}")
        logger.info("Using #{@locking ? "locking" : "non-locking"} mode")
        logger.info("Handling split keys: #{split_keys ? split_keys.join(", ") : "(all of them)"}")

        while !@gracefully_shutting_down
          was_something_changed = consumer.process
          if !was_something_changed
            STDOUT.flush
            sleep sleep_on_empty
          end
        end

        logger.info "Gracefully shutting down"
      end

      private
      attr_reader :consumer, :logger, :sleep_on_empty, :split_keys

      def prepare_traps
        Signal.trap("INT") { initiate_graceful_shutdown }
        Signal.trap("TERM") { initiate_graceful_shutdown }
      end

      def initiate_graceful_shutdown
        @gracefully_shutting_down = true
      end
    end
  end
end
