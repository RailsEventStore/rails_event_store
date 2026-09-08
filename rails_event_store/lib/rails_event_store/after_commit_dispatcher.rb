# frozen_string_literal: true

module RailsEventStore
  class AfterCommitDispatcher
    # Flushing a buffering scheduler leans on Transaction#after_commit, which
    # ActiveRecord grew in 7.2.
    MINIMUM_RAILS_VERSION = Gem::Version.new("7.2")

    def initialize(scheduler:)
      @scheduler = scheduler
      if buffering_scheduler? && !supported_rails_version?
        raise "#{scheduler.class} requires Rails #{MINIMUM_RAILS_VERSION} or newer"
      end
    end

    def call(subscriber, _, record)
      run { @scheduler.call(subscriber, record) }
    end

    def run(&schedule_proc)
      connection = ActiveRecord::Base.try(:lease_connection) || ActiveRecord::Base.connection
      transaction = connection.current_transaction

      if transaction.joinable?
        transaction.add_record(async_record(schedule_proc))
        transaction.after_commit { @scheduler.flush } if buffering_scheduler?
      else
        yield
        @scheduler.flush if buffering_scheduler?
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

    def buffering_scheduler?
      BufferingScheduler === @scheduler
    end

    def supported_rails_version?
      ActiveRecord.gem_version >= MINIMUM_RAILS_VERSION
    end
  end
end
