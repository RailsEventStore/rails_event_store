# frozen_string_literal: true

module RubyEventStore
  module Outbox
    class SidekiqProcessor
      InvalidPayload = Class.new(StandardError)

      def initialize(redis)
        @redis = redis
      end

      def process(record, now)
        parsed_record = JSON.parse(record.payload)

        queue = parsed_record["queue"]
        raise InvalidPayload.new("Missing queue") if queue.nil? || queue.empty?
        payload = JSON.generate(parsed_record.merge({
          "enqueued_at" => now.to_f,
        }))

        redis.lpush("queue:#{queue}", payload)
      end

      private
      attr_reader :redis
    end
  end
end
