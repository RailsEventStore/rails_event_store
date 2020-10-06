# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class InstrumentedMapper
      def initialize(mapper, instrumentation)
        @mapper = mapper
        @instrumentation = instrumentation
      end

      def event_to_record(domain_event)
        instrumentation.instrument("serialize.mapper.rails_event_store", domain_event: domain_event) do
          mapper.event_to_record(domain_event)
        end
      end

      def record_to_event(record)
        instrumentation.instrument("deserialize.mapper.rails_event_store", record: record) do
          mapper.record_to_event(record)
        end
      end

      def serializer
        mapper.serializer
      end

      private

      attr_reader :instrumentation, :mapper
    end
  end
end
