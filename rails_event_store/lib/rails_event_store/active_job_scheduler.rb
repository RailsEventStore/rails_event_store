# frozen_string_literal: true

require 'active_job'

module RailsEventStore
  class ActiveJobScheduler
    def call(klass, serialized_record)
      klass.perform_later(serialized_record.to_h)
    end

    def verify(subscriber)
      Class === subscriber && !!(subscriber < ActiveJob::Base)
    end
  end
end
