module RubyEventStore
  module CorrelatedMessages
    def self.metadata_for(event)
      {
        correlation_id: event.correlation_id || event.message_id,
        causation_id: event.message_id
      }
    end
  end
end
