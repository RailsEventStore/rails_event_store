require "sidekiq"
require "active_support/core_ext/hash/keys"

module RubyEventStore
  class SidekiqScheduler
    def initialize(serializer:)
      @serializer = serializer
    end

    def call(klass, record)
      klass.perform_async(record.serialize(serializer).to_h.deep_stringify_keys)
    end

    def verify(subscriber)
      Class === subscriber && !!(subscriber < Sidekiq::Worker)
    end

    private

    attr_reader :serializer
  end
end
