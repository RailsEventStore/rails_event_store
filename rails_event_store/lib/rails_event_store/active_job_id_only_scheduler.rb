# frozen_string_literal: true

require "active_job"

module RailsEventStore
  class ActiveJobIdOnlyScheduler
    def call(klass, record)
      klass.perform_later(payload_for(record))
    end

    def verify(subscriber)
      Class === subscriber && !!(subscriber < ActiveJob::Base)
    end

    private

    def payload_for(record)
      { "event_id" => record.event_id }
    end
  end
end
