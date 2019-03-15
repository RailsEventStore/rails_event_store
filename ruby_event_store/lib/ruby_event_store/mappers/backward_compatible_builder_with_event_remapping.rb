module RubyEventStore
  module Mappers
    class BackwardCompatibleBuilderWithEventRemapping
      def initialize(events_class_remapping)
        unless events_class_remapping.empty?
          warn <<~EOW
            events_class_remapping is deprecated. Provide custom event builder instead.
          EOW
        end
        @events_class_remapping = events_class_remapping
      end

      def call(event_type)
        type = @events_class_remapping.fetch(event_type) { event_type }
        Object.const_get(type)
      end
    end

    private_constant(:BackwardCompatibleBuilderWithEventRemapping)
  end
end
