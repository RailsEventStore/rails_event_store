# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    UnsupportedAdapter = Class.new(StandardError)
    InvalidDataTypeForAdapter = Class.new(StandardError)

    class DatabaseAdapter
      BIG_NUM = 169_614_201_293_062_129

      NOT_SET = Object.new.freeze
      private_constant :NOT_SET

      class PostgreSQL
        SUPPORTED_DATA_TYPES = %w[binary json jsonb].freeze
        private_constant :SUPPORTED_DATA_TYPES

        def initialize(data_type = NOT_SET)
          if !data_type.eql?(NOT_SET) && !supported_data_types.include?(data_type)
            raise InvalidDataTypeForAdapter,
                  "PostgreSQL doesn't support #{data_type.inspect}. Supported types are: #{supported_data_types.join(", ")}."
          end

          @data_type = data_type
        end

        attr_reader :data_type

        def supported_data_types
          SUPPORTED_DATA_TYPES
        end

        def eql?(other)
          other.instance_of?(PostgreSQL)
        end

        alias == eql?

        def hash
          PostgreSQL.hash ^ BIG_NUM
        end
      end

      class MySQL2
        SUPPORTED_DATA_TYPES = %w[binary json].freeze
        private_constant :SUPPORTED_DATA_TYPES

        def initialize(data_type = NOT_SET)
          if !data_type.eql?(NOT_SET) && !supported_data_types.include?(data_type)
            raise InvalidDataTypeForAdapter,
                  "MySQL2 doesn't support #{data_type.inspect}. Supported types are: #{supported_data_types.join(", ")}."
          end

          @data_type = data_type
        end

        attr_reader :data_type

        def supported_data_types
          SUPPORTED_DATA_TYPES
        end

        def eql?(other)
          other.instance_of?(MySQL2)
        end

        alias == eql?

        def hash
          MySQL2.hash ^ BIG_NUM
        end
      end

      class SQLite
        SUPPORTED_DATA_TYPES = %w[binary].freeze
        private_constant :SUPPORTED_DATA_TYPES

        def initialize(data_type = NOT_SET)
          if !data_type.eql?(NOT_SET) && !supported_data_types.include?(data_type)
            raise InvalidDataTypeForAdapter,
                  "SQLite doesn't support #{data_type.inspect}. Supported types are: #{supported_data_types.join}."
          end

          @data_type = data_type
        end

        attr_reader :data_type

        def supported_data_types
          SUPPORTED_DATA_TYPES
        end

        def eql?(other)
          other.instance_of?(SQLite)
        end

        alias == eql?

        def hash
          SQLite.hash ^ BIG_NUM
        end
      end

      def self.new(adapter_name, data_type = NOT_SET)
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
    end
  end
end
