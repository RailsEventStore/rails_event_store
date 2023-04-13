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
        @sequel = ::Sequel.connect(database_uri)
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
        false
      end

      def supports_position_queries?
        false
      end

      def supports_event_in_stream_query?
        false
      end

      def has_connection_pooling?
        false
      end

      def connection_pool_size
      end

      protected

      def load_schema
        @sequel.create_table(:event_store_events) do
          primary_key :id
          column :event_id, "varchar(36)", null: false
          column :event_type, "varchar", null: false
          column :data, "blob", null: false
          column :metadata, "blob"
          column :created_at, "datetime(6)", null: false
          column :valid_at, "datetime(6)"

          index :event_id, unique: true
        end
        @sequel.create_table(:event_store_events_in_streams) do
          primary_key :id
          column :event_id, "varchar(36)", null: false
          column :stream, "varchar", null: false
          column :position, "integer"
          column :created_at, "datetime(6)", null: false

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
