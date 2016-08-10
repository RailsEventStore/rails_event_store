module AggregateRoot
  class Repository
    def initialize(event_store = default_event_store)
      @event_store = event_store
    end

    def store(aggregate)
      aggregate.unpublished_events.each do |event|
        event_store.publish_event(event, stream_name: aggregate.id)
      end
    end

    def load(aggregate)
      events = event_store.read_stream_events_forward(aggregate.id)
      events.each do |event|
        aggregate.apply_old_event(event)
      end
    end

    attr_accessor :event_store

    def default_event_store
      AggregateRoot.configuration.default_event_store
    end
  end
end
