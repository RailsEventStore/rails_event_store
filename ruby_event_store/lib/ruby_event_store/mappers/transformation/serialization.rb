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

        def dump(record)
          Record.new(
            event_id:   record.event_id,
            metadata:   serializer.dump(record.metadata),
            data:       serializer.dump(record.data),
            event_type: record.event_type
          )
        end

        def load(record)
          Record.new(
            event_id:   record.event_id,
            metadata:   serializer.load(record.metadata),
            data:       serializer.load(record.data),
            event_type: record.event_type
          )
        end
      end
    end
  end
end
