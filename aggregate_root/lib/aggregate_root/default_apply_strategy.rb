module AggregateRoot
  class DefaultApplyStrategy
    def call(aggregate, event)
      event_name_processed = event.class.name.demodulize.underscore
      aggregate.method("apply_#{event_name_processed}").call(event)
    end
  end
end
