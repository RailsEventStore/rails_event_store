# frozen_string_literal: true

require "active_job"

module RailsEventStore
  module BulkEnqueue
    BUFFER_KEY = :rails_event_store_bulk_enqueue_buffers

    # ActiveJob.perform_all_later arrived in 7.1, but AfterCommitDispatcher only
    # knows when to flush a buffering scheduler on 7.2, where ActiveRecord grew
    # Transaction#after_commit.
    MINIMUM_RAILS_VERSION = Gem::Version.new("7.2")

    def initialize(...)
      raise "#{self.class} requires Rails #{MINIMUM_RAILS_VERSION} or newer" unless supported_rails_version?
      super
    end

    def call(klass, record)
      payload = payload_for(record)

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

    def supported_rails_version?
      ActiveJob.gem_version >= MINIMUM_RAILS_VERSION
    end

    def buffer
      (Thread.current[BUFFER_KEY] ||= {})[self] ||= []
    end
  end
end
