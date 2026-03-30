# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class EventClassRemapper
        def initialize(class_map)
          warn <<~EOW
            DEPRECATION WARNING: `RubyEventStore::Mappers::Transformation::EventClassRemapper` is deprecated and will be removed in the next major release.
            Use `RubyEventStore::Mappers::Transformation::Upcast` instead.
          EOW
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
            valid_at: record.valid_at,
          )
        end

        private

        attr_reader :class_map
      end
    end
  end
end
