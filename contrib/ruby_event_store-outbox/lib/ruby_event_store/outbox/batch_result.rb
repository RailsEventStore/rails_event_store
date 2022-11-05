module RubyEventStore
  module Outbox
    class BatchResult
      def self.empty
        new
      end

      def initialize
        @failed_record_ids = []
        @updated_record_ids = []
      end

      attr_reader :failed_record_ids, :updated_record_ids

      def success_count
        updated_record_ids.size
      end

      def failed_count
        failed_record_ids.size
      end
    end
  end
end
