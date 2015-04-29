module RailsEventStore
  module PubSub
    class Broker

      def initialize
        @subscribers = {}
      end

      def add_subscriber(subscriber, event_types)
        raise SubscriberNotExist  if subscriber.nil?
        raise MethodNotDefined    unless subscriber.methods.include? :handle_event
        subscribe(subscriber, [*event_types])
      end

      def notify_subscribers(event)
        notify(event, event.event_type)
        notify(event, ALL_EVENTS)
      end

      private
      attr_reader :subscribers

      def subscribe(subscriber, event_types)
        event_types.each do |type|
          (subscribers[type] ||= []) << subscriber
        end
      end

      def notify(event, event_type)
        if subscribers.key? event_type
          subscribers[event_type].each do |subscriber|
            subscriber.handle_event(event)
          end
        end
      end
    end
  end
end
