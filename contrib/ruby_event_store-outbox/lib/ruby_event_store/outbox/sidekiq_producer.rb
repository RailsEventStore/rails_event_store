# frozen_string_literal: true

require "sidekiq"
require_relative "sidekiq5_format"
require_relative "repository"

module RubyEventStore
  module Outbox
    class SidekiqProducer
      def call(klass, args)
        item = { "args" => args.map(&:to_h).map { |h| h.transform_keys(&:to_s) }, "class" => klass }
        normalized_item = sidekiq_client.__send__(:normalize_item, item)
        payload =
          sidekiq_client
            .middleware
            .invoke(normalized_item["class"], normalized_item, normalized_item["queue"], Sidekiq.redis_pool) do
              normalized_item
            end
        if payload
          Repository::Record.create!(
            format: SIDEKIQ5_FORMAT,
            split_key: payload.fetch("queue"),
            payload: payload.to_json,
          )
        end
      end

      private

      attr_reader :repository

      def sidekiq_client
        @sidekiq_client ||=
          if Gem::Version.new(Sidekiq::VERSION) < Gem::Version.new("7.0.0")
            Sidekiq::Client.new(Sidekiq.redis_pool)
          else
            Sidekiq::Client.new(pool: Sidekiq.redis_pool)
          end
      end
    end
  end
end
