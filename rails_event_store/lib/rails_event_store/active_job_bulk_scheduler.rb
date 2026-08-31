# frozen_string_literal: true

require "active_job"

module RailsEventStore
  class ActiveJobBulkScheduler < ActiveJobScheduler
    BUFFER_KEY = :rails_event_store_active_job_bulk_scheduler_buffers

    # ActiveJob.perform_all_later arrived in 7.1, but AfterCommitDispatcher only
    # knows when to flush this scheduler on 7.2, where ActiveRecord grew
    # Transaction#after_commit.
    MINIMUM_RAILS_VERSION = Gem::Version.new("7.2")

    def initialize(serializer:)
      unless ActiveJob.gem_version >= MINIMUM_RAILS_VERSION
        raise "#{self.class} requires Rails #{MINIMUM_RAILS_VERSION} or newer"
      end
      super
    end

    def call(klass, record)
      payload = serialized(record)

      if klass.instance_of?(ActiveJob::ConfiguredJob)
        flush
        klass.perform_later(payload)
      else
        buffer << klass.new(payload)
      end
    end

    def flush
      return if buffer.empty?

      ActiveJob.perform_all_later(buffer)
      buffer.clear
    end

    private

    def buffer
      (Thread.current[BUFFER_KEY] ||= {})[self] ||= []
    end
  end
end
