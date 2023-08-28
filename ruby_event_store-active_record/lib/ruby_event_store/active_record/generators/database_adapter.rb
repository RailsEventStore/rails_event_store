# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    UnsupportedAdapter = Class.new(StandardError)

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

      class MySQL2
        def eql?(other)
          other.instance_of?(MySQL2)
        end

        alias == eql?

        def hash
          MySQL2.hash ^ BIG_NUM
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
        when "mysql2"
          MySQL2.new
        when "sqlite"
          Sqlite.new
        else
          raise UnsupportedAdapter, "Unsupported adapter: #{adapter_name.inspect}"
        end
      end
    end
  end
end