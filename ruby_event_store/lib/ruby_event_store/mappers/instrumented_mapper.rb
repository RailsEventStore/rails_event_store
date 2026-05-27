# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class InstrumentedMapper
      def initialize(mapper, instrumentation)
        @mapper = mapper
        @instrumentation = instrumentation
      end

      def event_to_record(event)
        instrumentation.instrument("event_to_record.mapper.ruby_event_store", event: event) do
          deprecated_instrument(
            "serialize.mapper.ruby_event_store",
            { domain_event: event },
            canonical: "event_to_record.mapper.ruby_event_store",
            key: :instrumented_mapper_serialize_deprecated,
          ) { mapper.event_to_record(event) }
        end
      end

      def record_to_event(record)
        instrumentation.instrument("record_to_event.mapper.ruby_event_store", record: record) do
          deprecated_instrument(
            "deserialize.mapper.ruby_event_store",
            { record: record },
            canonical: "record_to_event.mapper.ruby_event_store",
            key: :instrumented_mapper_serialize_deprecated,
          ) { mapper.record_to_event(record) }
        end
      end

      private

      attr_reader :instrumentation, :mapper

      def deprecated_instrument(name, payload, canonical:, key:, &block)
        old_listeners = instrumentation.notifier.all_listeners_for(name)
        new_listeners = instrumentation.notifier.all_listeners_for(canonical)
        if (old_listeners - new_listeners).any?
          Deprecations.warn(key)
          instrumentation.instrument(name, payload, &block)
        else
          yield
        end
      end
    end
  end
end
