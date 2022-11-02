module RubyEventStore
  module Outbox
    class Tempo
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
        if @max_batch_size > @batch_size
          [@batch_size * 2, @max_batch_size].min
        else
          @batch_size
        end
      end
    end
  end
end
