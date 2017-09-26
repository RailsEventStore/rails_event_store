module RubyEventStore
  module PubSub
    class Dispatcher
      def call(subscriber, event)
        subscriber.call(event)
      end

      def proxy_for(klass)
        raise InvalidHandler.new(klass) unless klass.method_defined?(:call)
        ->(e) { klass.new.call(e) }
      end
    end
  end
end
