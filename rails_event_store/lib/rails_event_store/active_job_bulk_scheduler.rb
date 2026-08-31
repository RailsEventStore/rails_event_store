# frozen_string_literal: true

require "active_job"

module RailsEventStore
  class ActiveJobBulkScheduler < ActiveJobScheduler
    BUFFER_KEY = :rails_event_store_active_job_bulk_scheduler_buffers
    ACTIVE_JOB_WITH_BULK_ENQUEUE = Gem::Version.new("7.1")

    def initialize(serializer:)
      unless ActiveJob.gem_version >= ACTIVE_JOB_WITH_BULK_ENQUEUE
        raise "#{self.class} requires ActiveJob #{ACTIVE_JOB_WITH_BULK_ENQUEUE} or newer"
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
