# frozen_string_literal: true

module RailsEventStore
  class AfterCommitAsyncDispatcher
    def initialize(scheduler:)
      @scheduler = scheduler
    end

    def call(subscriber, _, record)
      run { @scheduler.call(subscriber, record) }
    end

    def run(&schedule_proc)
      transaction = ActiveRecord::Base.connection.current_transaction

      if transaction.joinable?
        transaction.add_record(async_record(schedule_proc))
      else
        yield
      end
    end

    def async_record(schedule_proc)
      AsyncRecord.new(schedule_proc)
    end

    def verify(subscriber)
      @scheduler.verify(subscriber)
    end

    class AsyncRecord
      def initialize(schedule_proc)
        @schedule_proc = schedule_proc
      end

      def committed!(*)
        schedule_proc.call
      end

      def rolledback!(*)
      end

      def before_committed!
      end

      def trigger_transactional_callbacks?
      end

      attr_reader :schedule_proc
    end
  end
end
