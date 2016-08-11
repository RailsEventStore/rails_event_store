module AggregateRoot
  class DefaultApplyStrategy
    def call(aggregate, event)
      event_name_processed = event.class.to_s.underscore.gsub('/','_')
      aggregate.method("apply_#{event_name_processed}").call(event)
    end
  end
end
