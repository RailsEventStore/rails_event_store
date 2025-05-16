# frozen_string_literal: true

require "ruby_event_store/sequel"
require_relative "../../../support/helpers/rspec_defaults"
require_relative "../../../support/helpers/rspec_sql_matchers"
require "json"

ENV["DATABASE_URL"] ||= "sqlite::memory:"
ENV["DATA_TYPE"] ||= "text"

module RubyEventStore
  module Sequel
    class SpecHelper
      attr_reader :database_uri

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
        load_schema
        yield
      ensure
        drop_schema
      end

      def with_transaction
        yield
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
        !ENV["DATABASE_URL"].include?("sqlite")
      end

      def connection_pool_size
        sequel.pool.max_size
      end

      def sequel
        @sequel ||=
          ::Sequel
            .connect(
              database_uri,
              fractional_seconds: true,
              preconnect: :concurrently,
              max_connections: database_uri.include?("sqlite") ? 1 : 5,
            )
            .tap { |sequel| sequel.loggers << Logger.new(STDOUT) if ENV.has_key?("VERBOSE") }
      end

      protected

      def load_schema
        ::Sequel.extension :migration
        ::Sequel::Migrator.run(sequel, "lib/ruby_event_store/generators/templates/#{template_dir}", version: 0)
      end

      def drop_schema
        sequel.drop_table?(:event_store_events)
        sequel.drop_table?(:event_store_events_in_streams)
        sequel.drop_table?(:schema_info)
      end

      private

      def template_dir
        if ENV["DATABASE_URL"].include?("postgres")
          "postgres"
        elsif ENV["DATABASE_URL"].include?("mysql")
          "mysql"
        end
      end
    end
  end
end

::Sequel::Database.prepend(
  Module.new do
    def log_connection_yield(sql, _conn, args = nil)
      ActiveSupport::Notifications.instrument(
        "sql.sequel",
        sql: sql,
        name: "RubyEventStore::Sequel[#{database_type}]",
        binds: args,
      ) { super }
    end
  end,
)
