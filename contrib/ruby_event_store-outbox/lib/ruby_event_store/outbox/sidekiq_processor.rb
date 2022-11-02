# frozen_string_literal: true

require_relative "sidekiq5_format"

module RubyEventStore
  module Outbox
    class SidekiqProcessor
      InvalidPayload = Class.new(StandardError)

      def initialize(redis)
        @redis = redis
        @recently_used_queues = Set.new
      end

      def process(record, now)
        parsed_record = JSON.parse(record.payload)

        queue = parsed_record["queue"]
        raise InvalidPayload.new("Missing queue") if queue.nil? || queue.empty?
        payload = JSON.generate(parsed_record.merge({ "enqueued_at" => now.to_f }))

        redis.lpush("queue:#{queue}", payload)

        @recently_used_queues << queue
      rescue Redis::TimeoutError, Redis::ConnectionError
        raise RetriableError
      end

      def after_batch
        ensure_that_sidekiq_knows_about_all_queues
      end

      def message_format
        SIDEKIQ5_FORMAT
      end

      private

      def ensure_that_sidekiq_knows_about_all_queues
        if !@recently_used_queues.empty?
          redis.sadd("queues", @recently_used_queues.to_a)
          @recently_used_queues.clear
        end
      end

      attr_reader :redis
    end
  end
end
