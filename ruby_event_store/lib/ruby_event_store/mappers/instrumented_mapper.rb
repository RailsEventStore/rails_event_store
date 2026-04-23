# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class InstrumentedMapper
      DEPRECATION_MESSAGE = <<~EOW
        Instrumentation event names *.rails_event_store are deprecated and will be removed in the next major release.
        Use *.ruby_event_store instead.
      EOW
      private_constant :DEPRECATION_MESSAGE

      RENAME_DEPRECATION_MESSAGE = <<~EOW
        Instrumentation event names serialize.mapper.ruby_event_store and deserialize.mapper.ruby_event_store are deprecated and will be removed in the next major release.
        Use event_to_record.mapper.ruby_event_store and record_to_event.mapper.ruby_event_store instead.
        The domain_event: payload key in serialize.mapper.ruby_event_store has been renamed to event: in event_to_record.mapper.ruby_event_store.
      EOW
      private_constant :RENAME_DEPRECATION_MESSAGE

      def initialize(mapper, instrumentation)
        @mapper = mapper
        @instrumentation = instrumentation
      end

      def event_to_record(event)
        instrumentation.instrument("event_to_record.mapper.ruby_event_store", event: event) do
          deprecated_instrument("serialize.mapper.ruby_event_store", { domain_event: event },
                                canonical: "event_to_record.mapper.ruby_event_store",
                                message: RENAME_DEPRECATION_MESSAGE) do
            deprecated_instrument("serialize.mapper.rails_event_store", { domain_event: event }) do
              mapper.event_to_record(event)
            end
          end
        end
      end

      def record_to_event(record)
        instrumentation.instrument("record_to_event.mapper.ruby_event_store", record: record) do
          deprecated_instrument("deserialize.mapper.ruby_event_store", { record: record },
                                canonical: "record_to_event.mapper.ruby_event_store",
                                message: RENAME_DEPRECATION_MESSAGE) do
            deprecated_instrument("deserialize.mapper.rails_event_store", { record: record }) do
              mapper.record_to_event(record)
            end
          end
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

      def deprecated_instrument(name, payload, canonical: nil, message: DEPRECATION_MESSAGE, &block)
        canonical_name = canonical || name.sub("rails_event_store", "ruby_event_store")
        old_listeners = instrumentation.notifier.all_listeners_for(name)
        new_listeners = instrumentation.notifier.all_listeners_for(canonical_name)
        if (old_listeners - new_listeners).any?
          warn message
          instrumentation.instrument(name, payload, &block)
        else
          yield
        end
      end
    end
  end
end
