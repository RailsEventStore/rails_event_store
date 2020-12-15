module RubyEventStore
  module Mappers
    class DeprecatedWrapper
      def initialize(mapper)
        @mapper = mapper
      end

      def serializer
        @mapper.serializer
      end

      def event_to_record(any)
        @mapper.event_to_record(any)
      rescue NoMethodError => e
        raise unless e.message =~ /undefined method `event_to_record/
        warn <<~EOW
          Deprecation: Please rename #{@mapper.class}#event_to_serialized_record to #{@mapper.class}#event_to_record.
        EOW
        @mapper.event_to_serialized_record(any)
      end

      def record_to_event(any)
        @mapper.record_to_event(any)
      rescue NoMethodError => e
        raise unless e.message =~ /undefined method `record_to_event/
        warn <<~EOW
          Deprecation: Please rename #{@mapper.class}#serialized_record_to_event to #{@mapper.class}#record_to_event.
        EOW
        @mapper.serialized_record_to_event(any)
      end
    end
  end
end
