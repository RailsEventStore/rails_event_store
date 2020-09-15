require "active_support/core_ext/hash/indifferent_access"
require 'ruby_event_store'

module Transformations
  class WithIndifferentAccess
    def dump(item)
      RubyEventStore::Mappers::Transformation::Item.new(
        event_id:   item.event_id,
        metadata:   ActiveSupport::HashWithIndifferentAccess.new(item.metadata).deep_symbolize_keys,
        data:       ActiveSupport::HashWithIndifferentAccess.new(item.data).deep_symbolize_keys,
        event_type: item.event_type,
        timestamp:  item.timestamp
      )
    end

    def load(item)
      RubyEventStore::Mappers::Transformation::Item.new(
        event_id:   item.event_id,
        metadata:   ActiveSupport::HashWithIndifferentAccess.new(item.metadata),
        data:       ActiveSupport::HashWithIndifferentAccess.new(item.data),
        event_type: item.event_type,
        timestamp:  item.timestamp
      )
    end
  end
end
