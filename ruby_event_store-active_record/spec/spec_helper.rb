# frozen_string_literal: true

require "ruby_event_store/active_record"
require_relative "../../support/helpers/rspec_defaults"
require_relative "../../support/helpers/rspec_sql_matchers"
require_relative "../../support/helpers/migrator"
require_relative "../../support/helpers/schema_helper"

ENV["DATABASE_URL"] ||= "sqlite3::memory:"
ENV["DATA_TYPE"] ||= "binary"

$verbose = ENV.has_key?("VERBOSE") ? true : false
ActiveRecord::Schema.verbose = $verbose

module RubyEventStore
  module ActiveRecord
    class SpecHelper
      include SchemaHelper

      def serializer
        Serializers::YAML
      end

      def run_lifecycle
        establish_database_connection
        load_database_schema
        reset_column_information
        yield
      ensure
        drop_database
      end

      def with_transaction
        ::ActiveRecord::Base.transaction { yield }
      end

      def supports_concurrent_auto?
        !ENV["DATABASE_URL"].include?("sqlite")
      end

      def supports_concurrent_any?
        !ENV["DATABASE_URL"].include?("sqlite")
      end

      def supports_binary?
        ENV["DATA_TYPE"] == "binary"
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
        true
      end

      def connection_pool_size
        ::ActiveRecord::Base.connection.pool.size
      end

      def reset_column_information
        ::ActiveRecord::Base.reset_column_information
      end
    end

    class NativeTruncationSpecHelper < SpecHelper
      TRUNCATED_AT = "add_truncated_at_to_event_store_events_in_streams"
      STREAMS_METADATA = "create_event_store_streams_metadata"
      SUPPORT_HELPERS = File.expand_path("../../support/helpers", __dir__)

      def run_lifecycle
        establish_database_connection
        load_database_schema
        add_truncated_at
        add_streams_metadata
        reset_column_information
        yield
      ensure
        drop_streams_metadata
        drop_database
      end

      def add_truncated_at
        ::ActiveRecord::Migration.suppress_messages do
          Migrator.new(File.expand_path(template_path, SUPPORT_HELPERS)).run_migration(
            TRUNCATED_AT,
            connection: ::ActiveRecord::Base.connection,
          )
        end
      end

      def remove_truncated_at
        ::ActiveRecord::Migration.suppress_messages do
          Migrator.const_get(TRUNCATED_AT.camelize).new.exec_migration(::ActiveRecord::Base.connection, :down)
        end
        EventInStream.reset_column_information
      end

      def add_streams_metadata
        Migrator.new(File.expand_path("../lib/ruby_event_store/active_record/generators/templates", __dir__)).run_migration(
          STREAMS_METADATA,
        )
      end

      def drop_streams_metadata
        ::ActiveRecord::Migration.drop_table("event_store_streams_metadata", if_exists: true)
      end
    end
  end

  class CustomApplicationRecord < ::ActiveRecord::Base
    self.abstract_class = true
  end
end
