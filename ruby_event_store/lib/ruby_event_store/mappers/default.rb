require 'yaml'

module RubyEventStore
  module Mappers
    class Default
      ContractMissMatch = Class.new(StandardError)
      def initialize(serializer: YAML, events_class_remapping: {})
        raise ContractMissMatch unless serializer.respond_to?(:dump, :load)
        raise ContractMissMatch unless events_class_remapping.respond_to?(:fetch)
        @serializer = serializer
        @events_class_remapping = events_class_remapping
      end

      def event_to_serialized_record(domain_event)
        SerializedRecord.new(
          id:         domain_event.event_id,
          metadata:   serializer.dump(domain_event.metadata),
          data:       serializer.dump(domain_event.data),
          event_type: domain_event.class
        )
      end

      def serialized_record_to_event(record)
        event_type = events_class_remapping.fetch(record.event_type) { record.event_type }
        RubyEventStore::Constantizer.call(event_type).new(
          event_id: record.id,
          metadata: serializer.load(record.metadata),
          data:     serializer.load(record.data)
        )
      end

      private

      attr_reader :serializer, :events_class_remapping
    end
  end
end
