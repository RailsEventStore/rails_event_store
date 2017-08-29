module RubyEventStore
  module PubSub
    class Dispatcher
      def call(subscriber, event)
        subscriber.call(event)
      end
    end
  end
end
