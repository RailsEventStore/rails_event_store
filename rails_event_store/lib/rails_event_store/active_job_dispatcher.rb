require 'active_job'

module RailsEventStore
  class ActiveJobDispatcher
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
      ->(e) { klass.new.call(e) }
    end

    def async_proxy(klass)
      raise InvalidHandler.new(klass) unless klass.respond_to?(:perform_later)
      enqueue_now?(klass) ? enqueue_now_proxy(klass) : enqueue_after_commit_proxy(klass)
    end

    def enqueue_now_proxy(klass)
      ->(e) { klass.perform_later(YAML.dump(e)) }
    end

    def enqueue_after_commit_proxy(klass)
      ->(e) {
        if ActiveRecord::Base.connection.transaction_open?
          ActiveRecord::Base.
            connection.
            current_transaction.
            add_record( AsyncRecord.new(klass, e) )
        else
          klass.perform_later(YAML.dump(e))
        end
      }
    end

    def enqueue_now?(klass)
      %w(
        ActiveJob::QueueAdapters::InlineAdapter
        ActiveJob::QueueAdapters::TestAdapter
      ).include?(klass.queue_adapter.class.to_s)
    end

    class AsyncRecord
      def initialize(klass, event)
        @klass = klass
        @event = event
      end

      def has_transactional_callbacks?
        true
      end

      def committed!(*_, **__)
        @klass.perform_later(YAML.dump(@event))
      end
    end
  end
end
