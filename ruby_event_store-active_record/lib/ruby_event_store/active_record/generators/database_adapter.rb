# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    UnsupportedAdapter = Class.new(StandardError)

    class DatabaseAdapter
      BIG_NUM = 169614201293062129

      class PostgreSQL
        def eql?(other)
          other.instance_of?(PostgreSQL)
        end

        alias == eql?

        def hash
          PostgreSQL.hash ^ BIG_NUM
        end
      end

      class MySQL2
        def eql?(other)
          other.instance_of?(MySQL2)
        end

        alias == eql?

        def hash
          MySQL2.hash ^ BIG_NUM
        end
      end

      class SQLite
        def eql?(other)
          other.instance_of?(SQLite)
        end

        alias == eql?

        def hash
          SQLite.hash ^ BIG_NUM
        end
      end

      def self.new(adapter_name)
        case adapter_name.to_s.downcase
        when "postgresql", "postgis"
          PostgreSQL.new
        when "mysql2"
          MySQL2.new
        when "sqlite"
          SQLite.new
        else
          raise UnsupportedAdapter, "Unsupported adapter: #{adapter_name.inspect}"
        end
      end
    end
  end
end