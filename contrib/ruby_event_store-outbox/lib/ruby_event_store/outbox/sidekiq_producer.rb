# frozen_string_literal: true

require "sidekiq"
require_relative "sidekiq5_format"
require_relative "repositories/mysql57"

module RubyEventStore
  module Outbox
    class SidekiqProducer
      def initialize(repository)
        @repository = repository
      end

      def call(klass, args)
        sidekiq_client = Sidekiq::Client.new(Sidekiq.redis_pool)
        item = { "args" => args.map(&:to_h).map { |h| h.transform_keys(&:to_s) }, "class" => klass }
        normalized_item = sidekiq_client.__send__(:normalize_item, item)
        payload =
          sidekiq_client
            .middleware
            .invoke(normalized_item["class"], normalized_item, normalized_item["queue"], Sidekiq.redis_pool) do
              normalized_item
            end
        if payload
          repository.insert_record(SIDEKIQ5_FORMAT, payload.fetch("queue"), payload.to_json)
        end
      end

      private

      attr_reader :repository
    end
  end
end
