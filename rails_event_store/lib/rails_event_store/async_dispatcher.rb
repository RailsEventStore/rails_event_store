module RailsEventStore
  class AsyncDispatcher < RubyEventStore::PubSub::Dispatcher
    def initialize(proxy_strategy: AsyncProxyStrategy::Inline.new, async_call:)
      @async_proxy_strategy = proxy_strategy
      @async_call = async_call
    end

    def call(subscriber, _, serialized_event)
      if @async_call.async_handler?(subscriber)
        @async_proxy_strategy.call(->{ @async_call.call(subscriber, serialized_event) })
      else
        super
      end
    end

    def verify(subscriber)
      super unless @async_call.async_handler?(subscriber)
    end
  end
end
