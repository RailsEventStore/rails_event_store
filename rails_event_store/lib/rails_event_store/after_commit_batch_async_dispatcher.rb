# frozen_string_literal: true

module RailsEventStore
  class AfterCommitBatchAsyncDispatcher
    def initialize(scheduler:, batch_scheduler:)
      @scheduler = scheduler
      @batch_scheduler = batch_scheduler
      @transactions_records = {}
      @subscription_records = Hash.new { |h, k| h[k] = [] }
    end

    def call(subscriber, _, record)
      transaction = ActiveRecord::Base.connection.current_transaction

      if transaction.joinable?
        transaction.add_record(
          @transactions_records[transaction] = AsyncRecord.new(
            -> { run(transaction) },
            -> { clear(transaction) }
          )
        ) unless @transactions_records[transaction]
        @subscription_records[transaction] << [subscriber, record]
      else
        @scheduler.call(subscriber, record)
      end
    end

    def clear(transaction)
      @transactions_records.delete(transaction)
      @subscription_records.delete(transaction)
    end

    def run(transaction)
      @batch_scheduler.call(@subscription_records[transaction])
    end

    def verify(subscriber)
      @scheduler.verify(subscriber) && @batch_scheduler.verify(subscriber)
    end

    class AsyncRecord
      def initialize(schedule_proc, clear_proc)
        @schedule_proc = schedule_proc
        @clear_proc = clear_proc
      end

      def committed!(*)
        @schedule_proc.call
        @clear_proc.call
      end

      def rolledback!(*)
        @clear_proc.call
      end

      def before_committed!; end

      def trigger_transactional_callbacks?; end
    end
  end

  class ActiveJobBatchScheduler
    def initialize(serializer:)
      @serializer = serializer
    end

    def call(records)
      ActiveJob.perform_all_later(records.map { |subscriber, record| serialize(subscriber, record) })
    end

    def verify(subscriber)
      if Class === subscriber
        !!(subscriber < ActiveJob::Base)
      else
        subscriber.instance_of?(ActiveJob::ConfiguredJob)
      end
    end

    def serialize(subscriber, record)
      subscriber.new(record.serialize(serializer).to_h.transform_keys(&:to_s))
    end

    private

    attr_reader :serializer
  end
end
