# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class InstrumentedBatchMapper
      def initialize(mapper, instrumentation)
        @mapper = mapper
        @instrumentation = instrumentation
      end

      def events_to_records(events)
        instrumentation.instrument("events_to_records.mapper.ruby_event_store", domain_events: events) do
          instrumentation.instrument("events_to_records.mapper.rails_event_store", domain_events: events) do
            mapper.events_to_records(events)
          end
        end
      end

      def records_to_events(records)
        instrumentation.instrument("records_to_events.mapper.ruby_event_store", records: records) do
          instrumentation.instrument("records_to_events.mapper.rails_event_store", records: records) do
            mapper.records_to_events(records)
          end
        end
      end

      private

      attr_reader :instrumentation, :mapper
    end
  end
end
