# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class BatchMapper
      def initialize(mapper = Default.new)
        @mapper = mapper
      end

      def events_to_records(events)
        events.map { |event| @mapper.event_to_record(event) }
      end

      def records_to_events(records)
        records.map { |record| @mapper.record_to_event(record) }
      end
    end
  end
end
