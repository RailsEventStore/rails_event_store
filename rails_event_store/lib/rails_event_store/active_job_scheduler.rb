# frozen_string_literal: true

require "active_job"

module RailsEventStore
  class ActiveJobScheduler
    def initialize(serializer:)
      @serializer = serializer
    end

    def call(klass, record)
      klass.perform_later(serialized(record))
    end

    def verify(subscriber)
      if Class === subscriber
        !!(subscriber < ActiveJob::Base)
      else
        subscriber.instance_of?(ActiveJob::ConfiguredJob)
      end
    end

    private

    def serialized(record)
      record.serialize(serializer).to_h.transform_keys(&:to_s)
    end

    attr_reader :serializer
  end
end
