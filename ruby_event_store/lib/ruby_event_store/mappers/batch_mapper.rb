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

      def cleaner_inspect(indent: 0)
        <<~EOS.chomp
          #{' ' * indent}#<#{self.class}:0x#{__id__.to_s(16)}>
          #{' ' * indent}  - mapper: #{@mapper.respond_to?(:cleaner_inspect) ? @mapper.cleaner_inspect(indent: indent + 2) : @mapper.inspect}
        EOS
      end
    end
  end
end
