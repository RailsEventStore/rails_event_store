# frozen_string_literal: true

module RailsEventStore
  module AsyncHandler
    def perform(payload)
      super(Rails.configuration.event_store.deserialize(payload.symbolize_keys))
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