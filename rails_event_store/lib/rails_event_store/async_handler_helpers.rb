module RailsEventStore

  module AsyncHandler
    def perform(payload)
      super(Rails.configuration.event_store.deserialize(payload))
    end
  end

  module CorrelatedHandler
    def perform(event)
      Rails.configuration.event_store.with_metadata(
        CorrelatedMessages.metadata_for(event)
      ) do
        super
      end
    end
  end

end