# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    InvalidDataTypeForAdapter = Class.new(StandardError)
    UnsupportedAdapter = Class.new(StandardError)

    class VerifyDataTypeForAdapter
      SUPPORTED_POSTGRES_DATA_TYPES = %w[binary json jsonb].freeze
      SUPPORTED_MYSQL_DATA_TYPES = %w[binary json].freeze
      SUPPORTED_SQLITE_DATA_TYPES = %w[binary].freeze

      def call(adapter, data_type)
        raise UnsupportedAdapter, "Unsupported adapter" unless supported?(adapter)
        raise InvalidDataTypeForAdapter, "MySQL2 doesn't support #{data_type}" if is_mysql2?(adapter) && !SUPPORTED_MYSQL_DATA_TYPES.include?(data_type)
        raise InvalidDataTypeForAdapter, "sqlite doesn't support #{data_type}" if is_sqlite?(adapter) && supported_by_sqlite?(data_type)
        raise InvalidDataTypeForAdapter, "PostgreSQL doesn't support #{data_type}" unless supported_by_postgres?(data_type)
      end

      private

      def supported?(adapter)
        %w[mysql2 postgresql sqlite].include?(adapter.downcase)
      end

      def is_sqlite?(adapter)
        adapter.downcase.eql?("sqlite")
      end

      def is_mysql2?(adapter)
        adapter.downcase.eql?("mysql2")
      end

      def supported_by_sqlite?(data_type)
        !SUPPORTED_SQLITE_DATA_TYPES.include?(data_type)
      end

      def supported_by_postgres?(data_type)
        SUPPORTED_POSTGRES_DATA_TYPES.include?(data_type)
      end
    end
  end
end
