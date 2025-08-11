# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class InstrumentedMapper
      def initialize(mapper, instrumentation)
        @mapper = mapper
        @instrumentation = instrumentation
      end

      def event_to_record(event)
        instrumentation.instrument("serialize.mapper.rails_event_store", domain_event: event) do
          mapper.event_to_record(event)
        end
      end

      def record_to_event(record)
        instrumentation.instrument("deserialize.mapper.rails_event_store", record: record) do
          mapper.record_to_event(record)
        end
      end

      def cleaner_inspect(indent: 0)
        <<~EOS.chomp
          #{' ' * indent}#<#{self.class}:0x#{__id__.to_s(16)}>
          #{' ' * indent}  - mapper: #{mapper.respond_to?(:cleaner_inspect) ? mapper.cleaner_inspect(indent: indent + 2) : mapper.inspect}
        EOS
      end

      private

      attr_reader :instrumentation, :mapper
    end
  end
end
