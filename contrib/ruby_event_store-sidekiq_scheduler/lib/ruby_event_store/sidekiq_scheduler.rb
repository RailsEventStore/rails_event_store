require "sidekiq"
require "active_support/core_ext/hash/keys"

module RubyEventStore
  class SidekiqScheduler
    def initialize(serializer:)
      @serializer = serializer
    end

    def call(klass, record)
      klass.perform_async(deep_transform_keys(record.serialize(serializer).to_h, &:to_s))
    end

    def verify(subscriber)
      Class === subscriber && !!(subscriber < Sidekiq::Worker)
    end

    private

    attr_reader :serializer

    def deep_transform_keys(hash, &block)
      result = {}
      hash.each do |key, value|
        result[yield(key)] = value.instance_of?(Hash) ? deep_transform_keys(value, &block) : value
      end
      result
    end
  end
end
