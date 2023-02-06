# frozen_string_literal: true

module RubyEventStore
  module Transformations
    class EventClassRemapper
      def initialize(class_map)
        @class_map = class_map
      end

      def dump(record)
        record
      end

      def load(record)
        Record.new(
          event_id: record.event_id,
          event_type: class_map[record.event_type] || record.event_type,
          data: record.data,
          metadata: record.metadata,
          timestamp: record.timestamp,
          valid_at: record.valid_at
        )
      end

      private

      attr_reader :class_map
    end
  end
end
