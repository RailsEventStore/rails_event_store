require 'active_job'

module RailsEventStore
  # @deprecated Use RailsEventStore::ComposedDispatcher and RailsEventStore::ActiveJobScheduler instead
  class ActiveJobDispatcher < RubyEventStore::AsyncDispatcher
    def initialize(proxy_strategy: AsyncProxyStrategy::Inline.new)
      super(proxy_strategy: proxy_strategy, scheduler: ActiveJobScheduler.new)
      warn <<~EOW
        RailsEventStore::ActiveJobDispatcher has been deprecated.

        Use RailsEventStore::ComposedDispatcher and RailsEventStore::ActiveJobScheduler instead
      EOW
    end

    # @deprecated Use RailsEventStore::ActiveJobScheduler with RubyEventStore::ImmediateAsyncDispatcher or RailsEventStore::AfterCommitAsyncDispatcher instead
    class ActiveJobScheduler
      def initialize
        warn <<~EOW
          RailsEventStore::ActiveJobDispatcher::ActiveJobScheduler has been deprecated.

          Use RailsEventStore::ActiveJobScheduler with RubyEventStore::ImmediateAsyncDispatcher or RailsEventStore::AfterCommitAsyncDispatcher instead
        EOW
      end
      def call(klass, serialized_event)
        klass.perform_later(serialized_event.to_h)
      end

      def async_handler?(klass)
        Class === klass && klass < ActiveJob::Base
      end
    end
  end
end
