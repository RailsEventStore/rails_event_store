require "ruby_event_store/sequel"
require_relative "../../../support/helpers/rspec_defaults"

require "active_support/isolated_execution_state"
require "active_support/notifications"

ENV["DATABASE_URL"] ||= "sqlite::memory:"
ENV["DATA_TYPE"] ||= "text"

module RubyEventStore
  module Sequel
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
          column :created_at, Time, null: false
          column :valid_at, Time

          index :event_id, unique: true
        end
        @sequel.create_table(:event_store_events_in_streams) do
          primary_key :id
          column :event_id, String, null: false, limit: 36
          column :stream, String, null: false
          column :position, Integer
          column :created_at, Time, null: false

          index %i[stream position], unique: true
          index %i[stream event_id], unique: true
        end
      end

      def drop_schema
        @sequel.drop_table(:event_store_events)
        @sequel.drop_table(:event_store_events_in_streams)
      end
    end
  end
end
