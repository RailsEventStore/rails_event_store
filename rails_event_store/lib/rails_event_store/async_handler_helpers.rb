# frozen_string_literal: true

module RailsEventStore
  module AsyncHandler
    module ModuleMethods
      def perform(payload)
        super(event_store.deserialize(serializer: serializer, **payload.symbolize_keys))
      end
    end

    def self.with_defaults
      Module.new do
        def self.prepended(host_class)
          host_class.prepend AsyncHandler.with(event_store: Rails.configuration.event_store, serializer: YAML)
        end
      end
    end

    def self.with(event_store: Rails.configuration.event_store, serializer: YAML)
      Module.new do
        def self.prepended(host_class)
          host_class.prepend ModuleMethods
        end

        define_method :event_store do
          event_store
        end

        define_method :serializer do
          serializer
        end
      end
    end

    def self.prepended(host_class)
      host_class.prepend with_defaults
    end
  end

  module CorrelatedHandler
    def perform(event)
      Rails.configuration.event_store.with_metadata(
        correlation_id: event.metadata[:correlation_id] || event.event_id,
        causation_id: event.event_id
      ) do
        super
      end
    end
  end
end
