# frozen_string_literal: true

require "ruby_event_store/rom"
require "dry/inflector"
require_relative "../../../support/helpers/rspec_defaults"
require_relative "../../../support/helpers/rspec_sql_matchers"

ENV["DATABASE_URL"] ||= "sqlite::memory:"
ENV["DATA_TYPE"] ||= "text"

module RubyEventStore
  module ROM
    class SpecHelper
      attr_reader :rom_container, :database_uri

      def initialize(database_uri = ENV["DATABASE_URL"])
        @database_uri = database_uri
      end

      def serializer
        case ENV["DATA_TYPE"]
        when /json/
          JSON
        else
          RubyEventStore::Serializers::YAML
        end
      end

      def run_lifecycle
        load_gateway_schema
        yield
      ensure
        drop_gateway_schema
      end

      def with_transaction
        UnitOfWork.new(gateway) { yield }
      end

      def supports_concurrent_auto?
        has_connection_pooling?
      end

      def supports_concurrent_any?
        has_connection_pooling?
      end

      def supports_binary?
        ENV["DATA_TYPE"] == "text"
      end

      def supports_upsert?
        true
      end

      def supports_position_queries?
        true
      end

      def supports_event_in_stream_query?
        true
      end

      def has_connection_pooling?
        !gateway_type?(:sqlite)
      end

      def connection_pool_size
        gateway.connection.pool.size
      end

      protected

      def gateway
        @config ||=
          ::ROM::Configuration
            .new(
              :sql,
              database_uri,
              max_connections: /sqlite/.match?(database_uri) ? 1 : 5,
              preconnect: :concurrently,
              fractional_seconds: true,
            )
            .tap do |config|
              config.default.use_logger(Logger.new(STDOUT)) if ENV.has_key?("VERBOSE")
              config.default.run_migrations
            end
        @rom_container ||= ROM.setup(@config)

        rom_container.gateways.fetch(:default)
      end

      def gateway_type?(name)
        gateway.connection.database_type.eql?(name)
      end

      def load_gateway_schema
        gateway.run_migrations
      end

      def drop_gateway_schema
        gateway.connection.drop_table?("event_store_events")
        gateway.connection.drop_table?("event_store_events_in_streams")
        gateway.connection.drop_table?("schema_migrations")
      end
    end
  end
end

ROM::SQL.load_extensions(:active_support_notifications)
