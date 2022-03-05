require 'sidekiq'

module RubyEventStore
  class SidekiqScheduler
    def initialize(serializer:)
      @serializer = serializer
    end

    def call(klass, record)
      klass.perform_async(record.serialize(serializer).to_h.transform_keys(&:to_s))
    end

    def verify(subscriber)
      Class === subscriber && !!(subscriber < Sidekiq::Worker)
    end

    private
    attr_reader :serializer
  end
end
