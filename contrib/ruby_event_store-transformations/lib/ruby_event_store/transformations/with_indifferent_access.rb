# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"
require 'ruby_event_store'

module RubyEventStore
  module Transformations
    class WithIndifferentAccess
      def dump(item)
        Record.new(
          event_id:   item.event_id,
          metadata:   HashWithIndifferentAccess.new(item.metadata).deep_symbolize_keys,
          data:       HashWithIndifferentAccess.new(item.data).deep_symbolize_keys,
          event_type: item.event_type,
          timestamp:  item.timestamp,
          valid_at:   item.valid_at,
        )
      end

      def load(item)
        Record.new(
          event_id:   item.event_id,
          metadata:   HashWithIndifferentAccess.new(item.metadata),
          data:       HashWithIndifferentAccess.new(item.data),
          event_type: item.event_type,
          timestamp:  item.timestamp,
          valid_at:   item.valid_at,
        )
      end
    end
  end
end
