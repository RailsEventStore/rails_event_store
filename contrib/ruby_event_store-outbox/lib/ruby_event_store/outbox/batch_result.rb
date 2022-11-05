module RubyEventStore
  module Outbox
    class BatchResult
      def self.empty
        new
      end

      def initialize
        @success_count = 0
        @failed_count = 0
      end

      attr_reader :success_count, :failed_count

      def count_success!
        @success_count += 1
      end

      def count_failed!
        @failed_count += 1
      end
    end
  end
end
