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
    end
  end
end
