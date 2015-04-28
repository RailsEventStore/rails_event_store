module RailsEventStore
  module PubSub
    class Broker

      def initialize
        @subscribers = {}
      end

      def add_subscriber(subscriber, event_types)
        subscribe(subscriber, [*event_types])
      end

      def notify_subscribers(event)
        if subscribers.key? event.event_type
          subscribers[event.event_type].each do |subscriber|
            subscriber.handle_event(event)
          end
        end
      end

      private
      attr_reader :subscribers

      def subscribe(subscriber, event_types)
        event_types.each do |type|
          (subscribers[type] ||= []) << subscriber
        end
      end
    end
  end
end
