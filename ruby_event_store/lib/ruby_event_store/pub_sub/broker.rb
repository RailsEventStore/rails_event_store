module RubyEventStore
  module PubSub
    class Broker
      def initialize(subscriptions: Subscriptions.new, dispatcher: Dispatcher.new)
        @subscriptions = subscriptions
        @dispatcher = dispatcher
      end
      attr_reader :subscriptions, :dispatcher

      def call(event, serialized_event)
        subscribers = subscriptions.all_for(event.type)
        subscribers.each do |subscriber|
          dispatcher.call(subscriber, event, serialized_event)
        end
      end
    end
  end
end
