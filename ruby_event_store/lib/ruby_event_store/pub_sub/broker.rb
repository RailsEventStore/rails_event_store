module RubyEventStore
  module PubSub
    class Broker
      DEFAULT_DISPATCHER = Dispatcher.new

      def initialize(dispatcher: DEFAULT_DISPATCHER)
        @subscribers = Hash.new {|hsh, key| hsh[key] = [] }
        @global_subscribers = []
        @dispatcher = dispatcher
      end

      def add_subscriber(subscriber, event_types)
        subscriber = subscriber_or_proxy(subscriber)
        verify_subscriber(subscriber)
        subscribe(subscriber, event_types)
      end

      def add_global_subscriber(subscriber)
        subscriber = subscriber_or_proxy(subscriber)
        verify_subscriber(subscriber)
        @global_subscribers << subscriber

        ->() { @global_subscribers.delete(subscriber) }
      end

      def notify_subscribers(event)
        all_subscribers_for(event.class).each do |subscriber|
          dispatcher.call(subscriber, event)
        end
      end

      private
      attr_reader :subscribers, :dispatcher

      def subscriber_or_proxy(subscriber)
        subscriber.instance_of?(Class) ? proxy_for(subscriber) : subscriber
      end

      def proxy_for(klass)
        dispatcher.proxy_for(klass)
      end

      def verify_subscriber(subscriber)
        raise SubscriberNotExist if subscriber.nil?
        raise InvalidHandler.new(subscriber.class) unless subscriber.respond_to?(:call)
      end

      def subscribe(subscriber, event_types)
        event_types.each{ |type| subscribers[type.name] << subscriber }
        ->() {event_types.each{ |type| subscribers.fetch(type.name).delete(subscriber) } }
      end

      def all_subscribers_for(event_type)
        subscribers[event_type.name] + @global_subscribers
      end
    end
  end
end
