# frozen_string_literal: true

require 'active_job'

module RailsEventStore
  class ActiveJobScheduler
    def call(subscription, serialized_event)
      klass = subscription.subscriber
      klass.perform_later(serialized_event.to_h)
    end

    def verify(subscriber)
      Class === subscriber && !!(subscriber < ActiveJob::Base)
    end
  end
end
