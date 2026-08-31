# frozen_string_literal: true

module RailsEventStore
  class AfterCommitDispatcher
    def initialize(scheduler:, model: ActiveRecord::Base)
      @scheduler = scheduler
      @model = model
    end

    def call(subscriber, _, record)
      run { @scheduler.call(subscriber, record) }
    end

    def run(&schedule_proc)
      transaction = current_transaction

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

    private

    def current_transaction
      connection = @model.try(:lease_connection) || @model.connection
      connection.current_transaction
    end
  end
end
