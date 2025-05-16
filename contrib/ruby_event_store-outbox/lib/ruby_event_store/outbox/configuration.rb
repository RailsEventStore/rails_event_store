# frozen_string_literal: true

module RubyEventStore
  module Outbox
    class Configuration
      def initialize(
        split_keys:,
        message_format:,
        batch_size:,
        database_url:,
        redis_url:,
        cleanup:,
        cleanup_limit:,
        sleep_on_empty:,
        locking:
      )
        @split_keys = split_keys
        @message_format = message_format
        @batch_size = batch_size || 100
        @database_url = database_url
        @redis_url = redis_url
        @cleanup = cleanup
        @cleanup_limit = cleanup_limit
        @sleep_on_empty = sleep_on_empty
        @locking = locking
        freeze
      end

      def with(overriden_options)
        self.class.new(
          split_keys: overriden_options.fetch(:split_keys, split_keys),
          message_format: overriden_options.fetch(:message_format, message_format),
          batch_size: overriden_options.fetch(:batch_size, batch_size),
          database_url: overriden_options.fetch(:database_url, database_url),
          redis_url: overriden_options.fetch(:redis_url, redis_url),
          cleanup: overriden_options.fetch(:cleanup, cleanup),
          cleanup_limit: overriden_options.fetch(:cleanup_limit, cleanup_limit),
          sleep_on_empty: overriden_options.fetch(:sleep_on_empty, sleep_on_empty),
          locking: overriden_options.fetch(:locking, locking),
        )
      end

      attr_reader :split_keys,
                  :message_format,
                  :batch_size,
                  :database_url,
                  :redis_url,
                  :cleanup,
                  :cleanup_limit,
                  :sleep_on_empty,
                  :locking
    end
  end
end
