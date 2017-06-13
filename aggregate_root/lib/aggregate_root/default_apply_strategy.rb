module AggregateRoot
  class DefaultApplyStrategy
    def call(aggregate, event)
      event_name_processed = event.class.name.demodulize.underscore
      handler_name = "apply_#{event_name_processed}"
      aggregate.method(handler_name).call(event) if aggregate.respond_to?(handler_name, true)
    end
  end
end
