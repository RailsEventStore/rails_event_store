# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/hash/keys"
require "ruby_event_store"

module RubyEventStore
  module Transformations
    class WithIndifferentAccess
      def dump(record)
        Record.new(
          event_id: record.event_id,
          metadata: record.metadata.deep_symbolize_keys,
          data: record.data.deep_symbolize_keys,
          event_type: record.event_type,
          timestamp: record.timestamp,
          valid_at: record.valid_at,
        )
      end

      def load(record)
        Record.new(
          event_id: record.event_id,
          metadata: HashWithIndifferentAccess.new(record.metadata),
          data: HashWithIndifferentAccess.new(record.data),
          event_type: record.event_type,
          timestamp: record.timestamp,
          valid_at: record.valid_at,
        )
      end
    end
  end
end
