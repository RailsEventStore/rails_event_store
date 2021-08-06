require 'ruby_event_store/rom'
require_relative '../../../support/helpers/rspec_defaults'
require 'dry/inflector'

ENV['DATABASE_URL'] ||= 'sqlite:db.sqlite3'

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
          fractional_seconds: true
        # sql_mode: %w[NO_AUTO_VALUE_ON_ZERO STRICT_ALL_TABLES]
        )
        # $stdout.sync = true
        # config.default.use_logger Logger.new(STDOUT)
        # config.default.connection.pool.send(:preconnect, true)
        config.default.run_migrations

        @rom_container = ROM.setup(config)
      end

      def run_lifecycle
        yield
      ensure
        drop_gateway_schema
        close_gateway_connection
      end

      def gateway
        rom_container.gateways.fetch(:default)
      end

      def gateway_type?(name)
        gateway.connection.database_type.eql?(name)
      end

      def has_connection_pooling?
        !gateway_type?(:sqlite)
      end

      def connection_pool_size
        gateway.connection.pool.size
      end

      def close_pool_connection
        gateway.connection.pool.disconnect
      end

      def supports_upsert?
        true
      end

      def supports_concurrent_any?
        has_connection_pooling?
      end

      def supports_concurrent_auto?
        has_connection_pooling?
      end

      def supports_binary?
        ENV['DATA_TYPE'] == 'text'
      end

      def supports_position_queries?
        true
      end

      def rescuable_concurrency_test_errors
        [::ROM::SQL::Error]
      end

      def cleanup_concurrency_test
        close_pool_connection
      end

      protected

      def drop_gateway_schema
        gateway.connection.drop_table?('event_store_events')
        gateway.connection.drop_table?('event_store_events_in_streams')
        gateway.connection.drop_table?('schema_migrations')
      end

      # See: https://github.com/rom-rb/rom-sql/blob/master/spec/shared/database_setup.rb
      def close_gateway_connection
        gateway.connection.disconnect
        # Prevent the auto-reconnect when the test completed
        # This will save from hardly reproducible connection run outs
        gateway.connection.pool.available_connections.freeze
      end
    end
  end
end

RSpec::Matchers.define :contains_ids do |expected_ids|
  match do |enum|
    @actual = enum.map(&:event_id)
    values_match?(expected_ids, @actual)
  end
  diffable
end

