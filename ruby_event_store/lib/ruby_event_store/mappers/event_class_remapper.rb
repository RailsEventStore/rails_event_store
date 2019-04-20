module RubyEventStore
  module Mappers
    class EventClassRemapper
      def initialize(class_map)
        @class_map = class_map
      end

      def dump(item)
        item
      end

      def load(item)
        item.merge(event_type: class_map.fetch(item.event_type) { item.event_type })
      end

      private
      attr_reader :class_map
    end
  end
end
