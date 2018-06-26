require 'active_job'

module RailsEventStore

  class ActiveJobDispatcher < AsyncDispatcher
    def initialize(proxy_strategy: AsyncProxyStrategy::Inline.new)
      super(proxy_strategy: proxy_strategy, async_call: ActiveJobCall.new)
    end

    class ActiveJobCall
      def call(klass, serialized_event)
        klass.perform_later(serialized_event.to_h)
      end

      def async_handler?(klass)
        Class === klass && klass < ActiveJob::Base
      end
    end
  end
end
