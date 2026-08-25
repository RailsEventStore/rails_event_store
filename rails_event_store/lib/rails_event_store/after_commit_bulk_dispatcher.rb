# frozen_string_literal: true

module RailsEventStore
  class AfterCommitBulkDispatcher
    REGISTRY_KEY = :rails_event_store_after_commit_bulk_dispatcher_batches

    def initialize(scheduler:)
      @scheduler = scheduler
    end

    def call(subscriber, _, record)
      connection = ActiveRecord::Base.try(:lease_connection) || ActiveRecord::Base.connection
      transaction = connection.current_transaction

      if transaction.joinable?
        batch_for(transaction).push(subscriber, record)
      else
        scheduler.call(subscriber, record)
      end
    end

    def verify(subscriber)
      @scheduler.verify(subscriber)
    end

    private

    attr_reader :scheduler

    def batch_for(transaction)
      registry[transaction] ||= register_batch(transaction)
    end

    def register_batch(transaction)
      Batch.new(scheduler) { registry.delete(transaction) }.tap do |batch|
        transaction.add_record(batch)
      end
    end

    def registry
      Thread.current[REGISTRY_KEY] ||= {}
    end

    class Batch
      attr_reader :subscribers_and_records

      def initialize(scheduler, &on_finalize)
        @scheduler = scheduler
        @on_finalize = on_finalize
        @subscribers_and_records = []
      end

      def push(subscriber, record)
        subscribers_and_records.push([subscriber, record])
      end

      def committed!(*)
        if @scheduler.respond_to?(:bulk_call)
          @scheduler.bulk_call(subscribers_and_records)
        else
          subscribers_and_records.each { |subscriber, record| @scheduler.call(subscriber, record) }
        end
      ensure
        @on_finalize.call
      end

      def rolledback!(*)
        @on_finalize.call
      end

      def before_committed!
      end

      def trigger_transactional_callbacks?
      end
    end

    private_constant :Batch
  end
end
