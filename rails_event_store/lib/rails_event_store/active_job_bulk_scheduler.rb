# frozen_string_literal: true

require "active_job"
require_relative "active_job_scheduler"

module RailsEventStore
  class ActiveJobBulkScheduler < ActiveJobScheduler
    def bulk_call(subscribers_and_records)
      jobs = []

      subscribers_and_records.each do |subscriber, record|
        payload = record.serialize(serializer).to_h.transform_keys(&:to_s)

        if subscriber.instance_of?(ActiveJob::ConfiguredJob)
          subscriber.perform_later(payload)
        else
          jobs << subscriber.new(payload)
        end
      end

      ActiveJob.perform_all_later(jobs) if jobs.any?
    end
  end
end
