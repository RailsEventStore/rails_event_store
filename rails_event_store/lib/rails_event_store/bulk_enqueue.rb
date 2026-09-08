# frozen_string_literal: true

require "active_job"

module RailsEventStore
  module BulkEnqueue
    include BufferingScheduler

    def call(klass, record)
      payload = payload_for(record)

      if klass.instance_of?(ActiveJob::ConfiguredJob)
        flush
        klass.perform_later(payload)
      else
        buffer << klass.new(payload)
      end
    end

    private

    def ship(jobs)
      ActiveJob.perform_all_later(jobs)
    end
  end
end
