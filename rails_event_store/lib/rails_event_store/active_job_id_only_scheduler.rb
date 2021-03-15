# frozen_string_literal: true

require "active_job"

module RailsEventStore
  class ActiveJobIdOnlyScheduler
    def call(klass, record)
      klass.perform_later({ "event_id" => record.event_id })
    end

    def verify(subscriber)
      Class === subscriber && !!(subscriber < ActiveJob::Base)
    end
  end
end
