module RubyEventStore
  module Mappers
    class NullMapper
      class AlmostLikeSerializedRecord < Struct.new(:domain_event)
        extend Forwardable
        def_delegators :domain_event, :event_id, :data, :metadata

        def event_type
          domain_event.type
        end
      end
      private_constant :AlmostLikeSerializedRecord

      def event_to_serialized_record(domain_event)
        AlmostLikeSerializedRecord.new(domain_event)
      end

      def serialized_record_to_event(record)
        record.domain_event
      end
    end
  end
end
