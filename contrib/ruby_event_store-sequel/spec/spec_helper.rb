require "ruby_event_store/sequel"
require_relative "../../../support/helpers/rspec_defaults"

require "active_support/isolated_execution_state"
require "active_support/notifications"

ENV["DATABASE_URL"] ||= "sqlite::memory:"
ENV["DATA_TYPE"] ||= "text"

module RubyEventStore
  module Sequel
    class SpecHelper
      def initialize(database_uri = ENV["DATABASE_URL"])
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
      end

      def drop_schema
      end
    end
  end
end
