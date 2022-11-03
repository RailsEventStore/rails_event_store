module RubyEventStore
  module Outbox
    class Tempo
      EXPONENTIAL_MULTIPLIER = 2

      def initialize(max_batch_size)
        raise ArgumentError if max_batch_size < 1
        @max_batch_size = max_batch_size
      end

      def batch_size
        @batch_size = next_batch_size
      end

      private

      def next_batch_size
        return 1 if @batch_size.nil?
        [@batch_size * EXPONENTIAL_MULTIPLIER, @max_batch_size].min
      end
    end
  end
end
