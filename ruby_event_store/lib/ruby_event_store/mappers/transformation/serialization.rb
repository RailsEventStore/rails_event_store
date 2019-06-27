# frozen_string_literal: true

require 'yaml'

module RubyEventStore
  module Mappers
    module Transformation
      class Serialization
        def initialize(serializer: YAML)
          @serializer = serializer
        end
        attr_reader :serializer

        def dump(item)
          Item.new(
            event_id:   item.event_id,
            metadata:   serializer.dump(item.metadata),
            data:       serializer.dump(item.data),
            event_type: item.event_type
          )
        end

        def load(item)
          Item.new(
            event_id:   item.event_id,
            metadata:   serializer.load(item.metadata),
            data:       serializer.load(item.data),
            event_type: item.event_type
          )
        end
      end
    end
  end
end
