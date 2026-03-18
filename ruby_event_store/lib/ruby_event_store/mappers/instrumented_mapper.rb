# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class InstrumentedMapper
      DEPRECATION_MESSAGE = <<~EOW
        Instrumentation event names *.rails_event_store are deprecated and will be removed in the next major release.
        Use *.ruby_event_store instead.
      EOW
      private_constant :DEPRECATION_MESSAGE

      def initialize(mapper, instrumentation)
        @mapper = mapper
        @instrumentation = instrumentation
      end

      def event_to_record(event)
        instrumentation.instrument("serialize.mapper.ruby_event_store", domain_event: event) do
          deprecated_instrument("serialize.mapper.rails_event_store", domain_event: event) do
            mapper.event_to_record(event)
          end
        end
      end

      def record_to_event(record)
        instrumentation.instrument("deserialize.mapper.ruby_event_store", record: record) do
          deprecated_instrument("deserialize.mapper.rails_event_store", record: record) do
            mapper.record_to_event(record)
          end
        end
      end

      private

      attr_reader :instrumentation, :mapper

      def deprecated_instrument(name, payload, &block)
        canonical_name = name.sub("rails_event_store", "ruby_event_store")
        old_listeners = instrumentation.notifier.all_listeners_for(name)
        new_listeners = instrumentation.notifier.all_listeners_for(canonical_name)
        if (old_listeners - new_listeners).any?
          warn DEPRECATION_MESSAGE
          instrumentation.instrument(name, payload, &block)
        else
          yield
        end
      end
    end
  end
end
