# frozen_string_literal: true

require "active_job"

module RailsEventStore
  class ActiveJobScheduler
    def initialize(serializer:)
      @serializer = serializer
    end

    def call(klass, record)
      klass.perform_later(payload_for(record))
    end

    def verify(subscriber)
      if Class === subscriber
        !!(subscriber < ActiveJob::Base)
      else
        subscriber.instance_of?(ActiveJob::ConfiguredJob)
      end
    end

    private

    def payload_for(record)
      record.serialize(serializer).to_h.transform_keys(&:to_s)
    end

    attr_reader :serializer
  end
end
