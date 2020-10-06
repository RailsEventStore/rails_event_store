# frozen_string_literal: true

require 'active_job'

module RailsEventStore
  class ActiveJobScheduler
    def initialize(serializer:)
      @serializer = serializer
    end

    def call(klass, record)
      klass.perform_later(record.serialize(serializer).to_h)
    end

    def verify(subscriber)
      Class === subscriber && !!(subscriber < ActiveJob::Base)
    end

    private
    attr_reader :serializer
  end
end
