require 'ruby_event_store/rom'
require_relative '../../../support/helpers/rspec_defaults'
require 'dry/inflector'

require 'active_support/notifications'
ROM::SQL.load_extensions(:active_support_notifications, :rails_log_subscriber)

module RubyEventStore
  module ROM
    class SpecHelper
      attr_reader :rom_container

      def initialize(database_uri = ENV['DATABASE_URL'])
        config = ::ROM::Configuration.new(
          :sql,
          database_uri,
          max_connections: database_uri =~ /sqlite/ ? 1 : 5,
          preconnect: :concurrently,
          fractional_seconds: true,
        )
        config.default.use_logger(Logger.new(STDOUT)) if ENV.has_key?("VERBOSE")
        config.default.run_migrations

        @rom_container = ROM.setup(config)
      end

      def run_lifecycle
        load_gateway_schema
        yield
      ensure
        drop_gateway_schema
      end

      def gateway
        rom_container.gateways.fetch(:default)
      end

      def supports_concurrent_auto?
        has_connection_pooling?
      end

      def supports_concurrent_any?
        has_connection_pooling?
      end

      def supports_binary?
        ENV['DATA_TYPE'] == 'text'
      end

      def supports_upsert?
        true
      end

      def has_connection_pooling?
        !gateway_type?(:sqlite)
      end

      def connection_pool_size
        gateway.connection.pool.size
      end

      def cleanup_concurrency_test
      end

      def rescuable_concurrency_test_errors
        [::ROM::SQL::Error]
      end

      def supports_position_queries?
        true
      end

      protected

      def gateway_type?(name)
        gateway.connection.database_type.eql?(name)
      end

      def load_gateway_schema
        gateway.run_migrations
      end

      def drop_gateway_schema
        gateway.connection.drop_table?('event_store_events')
        gateway.connection.drop_table?('event_store_events_in_streams')
        gateway.connection.drop_table?('schema_migrations')
      end
    end
  end
end

RSpec::Matchers.define :match_query_count_of do |expected_count|
  match do |query|
    count = 0
    ActiveSupport::Notifications.subscribed(
      lambda do |_name, _started, _finished, _unique_id, payload|
        unless %w[ CACHE SCHEMA ].include?(payload[:name])
          count += 1
        end
      end,
      "sql.rom",
      &actual
    )
    values_match?(expected_count, count)
  end
  supports_block_expectations
  diffable
end

