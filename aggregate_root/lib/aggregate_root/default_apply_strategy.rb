module AggregateRoot
  class DefaultApplyStrategy
    def handle(event, aggregate)
      event_name_processed = event.class.to_s.underscore
      aggregate.method("apply_#{event_name_processed}".to_sym).call(event)
    end
  end
end
