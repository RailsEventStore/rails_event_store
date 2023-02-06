# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class VerifyDataTypeForAdapter

      SUPPORTED_POSTGRES_DATA_TYPES = %w[binary json jsonb].freeze
      SUPPORTED_MYSQL_DATA_TYPES = %w[binary json].freeze
      SUPPORTED_SQLITE_DATA_TYPES = %w[binary].freeze

      def call(adapter, data_type)
        raise "unsupported adapter" unless %w[mysql2 postgresql sqlite].include?(adapter.downcase)
        raise "MySQL2 doesn't support #{data_type}" if adapter.downcase == "mysql2" && !SUPPORTED_MYSQL_DATA_TYPES.include?(data_type)
        raise "PostgreSQL doesn't support #{data_type}" if adapter.downcase == "postgresql" && !SUPPORTED_POSTGRES_DATA_TYPES.include?(data_type)
        raise "sqlite doesn't support #{data_type}" if adapter.downcase == "sqlite" && !SUPPORTED_SQLITE_DATA_TYPES.include?(data_type)
      end
    end
  end
end
