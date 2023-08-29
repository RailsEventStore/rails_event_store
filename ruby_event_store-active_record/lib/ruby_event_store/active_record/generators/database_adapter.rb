# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    UnsupportedAdapter = Class.new(StandardError)
    InvalidDataTypeForAdapter = Class.new(StandardError)

    class DatabaseAdapter
      NOT_SET = Object.new.freeze

      class PostgreSQL < self
        SUPPORTED_DATA_TYPES = %w[binary json jsonb].freeze

        def initialize(data_type = NOT_SET)
          super("postgresql", data_type)
        end
      end

      class MySQL2 < self
        SUPPORTED_DATA_TYPES = %w[binary json].freeze

        def initialize(data_type = NOT_SET)
          super("mysql2", data_type)
        end
      end

      class SQLite < self
        SUPPORTED_DATA_TYPES = %w[binary].freeze

        def initialize(data_type = NOT_SET)
          super("sqlite", data_type)
        end
      end

      def initialize(adapter_name, data_type)
        raise UnsupportedAdapter if instance_of?(DatabaseAdapter)

        validate_data_type!(data_type)

        @adapter_name = adapter_name
        @data_type = data_type
      end

      attr_reader :adapter_name, :data_type

      def supported_data_types
        self.class::SUPPORTED_DATA_TYPES
      end

      def eql?(other)
        other.is_a?(DatabaseAdapter) && adapter_name.eql?(other.adapter_name)
      end

      alias == eql?

      def hash
        DatabaseAdapter.hash ^ adapter_name.hash
      end

      def self.from_string(adapter_name, data_type = NOT_SET)
        raise NoMethodError unless eql?(DatabaseAdapter)

        case adapter_name.to_s.downcase
        when "postgresql", "postgis"
          PostgreSQL.new(data_type)
        when "mysql2"
          MySQL2.new(data_type)
        when "sqlite"
          SQLite.new(data_type)
        else
          raise UnsupportedAdapter, "Unsupported adapter: #{adapter_name.inspect}"
        end
      end

      private

      def validate_data_type!(data_type)
        if !data_type.eql?(NOT_SET) && !supported_data_types.include?(data_type)
          raise InvalidDataTypeForAdapter,
                "#{class_name} doesn't support #{data_type.inspect}. Supported types are: #{supported_data_types.join(", ")}."
        end
      end

      def class_name
        self.class.name.split("::").last
      end
    end
  end
end
