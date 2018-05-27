module RubyEventStore
  module Mappers
    class NullMapper

      def event_to_serialized_record(domain_event)
        domain_event
      end

      def serialized_record_to_event(record)
        record
      end

      def load_serialized_event(**serialized_event)
        serialized_event
      end
    end
  end
end
