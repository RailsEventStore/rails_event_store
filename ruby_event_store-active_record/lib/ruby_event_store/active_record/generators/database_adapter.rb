# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class DatabaseAdapter
      BIG_NUM = 169614201293062129

      class Postgres
        def eql?(other)
          other.instance_of?(Postgres)
        end

        alias == eql?

        def hash
          Postgres.hash ^ BIG_NUM
        end
      end

      class MySQL
        def eql?(other)
          other.instance_of?(MySQL)
        end

        alias == eql?

        def hash
          MySQL.hash ^ BIG_NUM
        end
      end

      class Sqlite
        def eql?(other)
          other.instance_of?(Sqlite)
        end

        alias == eql?

        def hash
          Sqlite.hash ^ BIG_NUM
        end
      end

      def self.new(adapter_name)
        case adapter_name.to_s.downcase
        when "postgresql", "postgis"
          Postgres.new
        when "mysql"
          MySQL.new
        when "sqlite"
          Sqlite.new
        else
          raise ArgumentError, "Unsupported adapter: #{adapter_name.inspect}"
        end
      end
    end
  end
end