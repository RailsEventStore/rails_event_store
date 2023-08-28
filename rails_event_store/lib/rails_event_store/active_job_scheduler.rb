# frozen_string_literal: true

require "active_job"

module RailsEventStore
  class ActiveJobScheduler
    def initialize(serializer:)
      @serializer = serializer
    end

    def call(klass, record)
      klass.perform_later(record.serialize(serializer).to_h.transform_keys(&:to_s))
    end

    def verify(subscriber)
      if Class === subscriber
        !!(subscriber < ActiveJob::Base)
      else
        subscriber.is_a?(ActiveJob::ConfiguredJob)
      end
    end

    private

    attr_reader :serializer
  end
end
