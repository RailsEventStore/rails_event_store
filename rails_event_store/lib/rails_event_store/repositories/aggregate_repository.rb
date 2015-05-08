module RailsEventStore
  module Repositories
    class AggregateRepository
      def initialize(event_store = default_event_store)
        @event_store = event_store
      end

      def store(aggregate)
        aggregate.unpublished_events.each do |event|
          event_store.publish_event(event, aggregate.id)
        end
      end

      attr_accessor :event_store

      def default_event_store
        Client.new
      end
    end
  end
end
