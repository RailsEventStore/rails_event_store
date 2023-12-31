# frozen_string_literal: true

module RailsEventStore
  module AsyncHandler
    def self.with_defaults
      with
    end

    def self.with(
      serializer: RubyEventStore::Serializers::YAML,
      event_store_locator: -> { Rails.configuration.event_store }
    )
      Module.new do
        define_method :perform do |payload|
          super(event_store_locator.call.deserialize(serializer: serializer, **payload.transform_keys(&:to_sym)))
        end
      end
    end

    def self.prepended(host_class)
      host_class.prepend with_defaults
    end
  end

  module AsyncHandlerJobIdOnly
    def self.with_defaults
      with
    end

    def self.with(
      event_store: Rails.configuration.event_store,
      event_store_locator: nil
    )
      Module.new do
        define_method :perform do |payload|
          event_store = event_store_locator.call if event_store_locator
          super(event_store.read.event(payload.fetch("event_id")))
        end
      end
    end

    def self.prepended(host_class)
      host_class.prepend with_defaults
    end
  end


  module CorrelatedHandler
    def perform(event)
      Rails
        .configuration
        .event_store
        .with_metadata(correlation_id: event.metadata[:correlation_id], causation_id: event.event_id) { super }
    end
  end
end
