module RubyEventStore
  module CorrelatedEvents
    def self.metadata_for(event)
      {
        correlation_id: event.metadata[:correlation_id] || event.event_id,
        causation_id: event.event_id
      }
    end
  end
end
