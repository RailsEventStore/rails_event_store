require 'active_job'

module RailsEventStore
  module AsyncProxyStrategy
    class AfterCommit
      def call(klass, event)
        if ActiveRecord::Base.connection.transaction_open?
          ActiveRecord::Base.
            connection.
            current_transaction.
            add_record(AsyncRecord.new(klass, event))
        else
          klass.perform_later(YAML.dump(event))
        end
      end

      private
      class AsyncRecord
        def initialize(klass, event)
          @klass = klass
          @event = event
        end

        def committed!
          @klass.perform_later(YAML.dump(@event))
        end

        def rolledback!(**_)
        end

        def before_committed!
        end
      end
    end

    class Inline
      def call(klass, event)
        klass.perform_later(YAML.dump(event))
      end
    end
  end

  class ActiveJobDispatcher
    def initialize(proxy_strategy: AsyncProxyStrategy::Inline.new)
      @async_proxy_strategy = proxy_strategy
    end

    def call(subscriber, event)
      subscriber.call(event)
    end

    def proxy_for(klass)
      async_handler?(klass) ? async_proxy(klass) : sync_proxy(klass)
    end

    private
    def async_handler?(klass)
      klass < ActiveJob::Base
    end

    def sync_proxy(klass)
      raise InvalidHandler.new(klass) unless klass.method_defined?(:call)
      klass.new
    end

    def async_proxy(klass)
      ->(e) { @async_proxy_strategy.call(klass, e) }
    end
  end
end
