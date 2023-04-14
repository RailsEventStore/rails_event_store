require "ruby_event_store/sequel"
require_relative "../../../support/helpers/rspec_defaults"

require "active_support/isolated_execution_state"
require "active_support/notifications"

ENV["DATABASE_URL"] ||= "sqlite::memory:"
ENV["DATA_TYPE"] ||= "text"

module RubyEventStore
  module Sequel
    module Instrumentation
      def log_connection_yield(sql, _conn, args = nil)
        ActiveSupport::Notifications.instrument(
          "sql.sequel",
          sql: sql,
          name: "RubyEventStore::Sequel[#{database_type}]",
          binds: args
        ) { super }
      end
    end
    ::Sequel::Database.prepend Instrumentation

    class SpecHelper
      attr_reader :sequel

      def initialize(database_uri = ENV["DATABASE_URL"])
        @sequel =
          ::Sequel.connect(
            database_uri,
            fractional_seconds: true,
            preconnect: :concurrently,
            max_connections: database_uri.include?("sqlite") ? 1 : 5
          )
        @sequel.loggers << Logger.new(STDOUT) if ENV.has_key?("VERBOSE")
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
        @sequel.pool.max_size
      end

      protected

      def load_schema
        @sequel.create_table(:event_store_events) do
          primary_key :id
          column :event_id, String, null: false, limit: 36
          column :event_type, String, null: false
          column :data, File, null: false
          column :metadata, File
          column :created_at, ENV.fetch("DATABASE_URL").start_with?("mysql") ? "datetime(6)" : Time, null: false
          column :valid_at, ENV.fetch("DATABASE_URL").start_with?("mysql") ? "datetime(6)" : Time

          index :event_id, unique: true,  name: "index_event_store_events_on_event_id"
        end
        @sequel.create_table(:event_store_events_in_streams) do
          timestamp_column_type =
            lambda do
              if ENV.fetch("DATABASE_URL").start_with? "mysql"
                "datetime(6)"
              else
                Time
              end
            end

          primary_key :id
          column :event_id, String, null: false, limit: 36
          column :stream, String, null: false
          column :position, Integer
          column :created_at, ENV.fetch("DATABASE_URL").start_with?("mysql") ? "datetime(6)" : Time, null: false

          index %i[stream position], unique: true, name: "index_event_store_events_in_streams_on_stream_and_position"
          index %i[stream event_id], unique: true, name: "index_event_store_events_in_streams_on_stream_and_event_id"
        end
      end

      def drop_schema
        @sequel.drop_table(:event_store_events)
        @sequel.drop_table(:event_store_events_in_streams)
      end
    end
  end
end

::RSpec::Matchers.define :match_query do |expected_query, expected_count = 1|
  match do
    count = 0
    ActiveSupport::Notifications.subscribed(
      lambda { |_, _, _, _, payload| count += 1 if expected_query === payload[:sql] },
      "sql.sequel",
      &actual
    )
    values_match?(expected_count, count)
  end
  supports_block_expectations
  diffable
end
