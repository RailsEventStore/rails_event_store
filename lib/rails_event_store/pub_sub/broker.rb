module RailsEventStore
  module PubSub
    class Broker

      def initialize
        @subscribers = Hash.new {|hsh, key| hsh[key] = [] }
      end

      def add_subscriber(subscriber, event_types)
        verify_subscriber(subscriber)
        subscribe(subscriber, event_types)
      end

      def add_global_subscriber(subscriber)
        verify_subscriber(subscriber)
        subscribe(subscriber, [ALL_EVENTS])
      end

      def notify_subscribers(event)
        [event.event_type, ALL_EVENTS].each do |type|
          notify(event, type)
        end
      end

      private
      attr_reader :subscribers

      def verify_subscriber(subscriber)
        raise SubscriberNotExist if subscriber.nil?
        raise MethodNotDefined unless subscriber.methods.include? :handle_event
      end

      def subscribe(subscriber, event_types)
        event_types.each do |type|
          subscribers[type] << subscriber
        end
      end

      def notify(event, event_type)
        subscribers[event_type].each do |subscriber|
          subscriber.handle_event(event)
        end
      end
    end
  end
end
