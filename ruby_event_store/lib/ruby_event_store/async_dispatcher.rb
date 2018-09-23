module RubyEventStore
  class AsyncDispatcher < PubSub::Dispatcher
    def initialize(proxy_strategy: AsyncProxyStrategy::Inline.new, scheduler:)
      @async_proxy_strategy = proxy_strategy
      @scheduler = scheduler
    end

    def call(subscriber, _, serialized_event)
      if @scheduler.async_handler?(subscriber)
        @async_proxy_strategy.call(->{ @scheduler.call(subscriber, serialized_event) })
      else
        super
      end
    end

    def verify(subscriber)
      @scheduler.async_handler?(subscriber) || super
    end
  end
end
