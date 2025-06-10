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
  end

  class CustomApplicationRecord < ::ActiveRecord::Base
    self.abstract_class = true
  end
end
