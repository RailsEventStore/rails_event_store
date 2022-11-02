module RubyEventStore
  module Outbox
    class Runner
      def initialize(consumer, configuration, logger:)
        @consumer = consumer
        @logger = logger
        @sleep_on_empty = configuration.sleep_on_empty
        @gracefully_shutting_down = false
        prepare_traps
      end

      def init
        consumer.init
      end

      def run
        while !@gracefully_shutting_down
          was_something_changed = consumer.one_loop
          if !was_something_changed
            STDOUT.flush
            sleep sleep_on_empty
          end
        end
        logger.info "Gracefully shutting down"
      end

      private
      attr_reader :consumer, :logger, :sleep_on_empty

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
