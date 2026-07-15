# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    # SQLite's LIKE is case-insensitive by default and only uses the index when the
    # column's collation matches the case_sensitive_like pragma. GLOB doesn't have that
    # problem, so SQLite gets its own strategy here.
    class StreamPrefixPattern
      def self.for(connection)
        connection.adapter_name.match?(/sqlite/i) ? Glob.new : Like.new
      end

      class Like
        def condition
          "stream LIKE ?"
        end

        # No explicit ESCAPE clause: both adapters already default to backslash, and an
        # explicit ESCAPE '\' literal is spelled differently on each and breaks on MySQL.
        def bind_value(prefix)
          "#{::ActiveRecord::Base.sanitize_sql_like(prefix)}%"
        end
      end

      class Glob
        def condition
          "stream GLOB ?"
        end

        def bind_value(prefix)
          "#{escape(prefix)}*"
        end

        private

        def escape(string)
          string.gsub(/[\[*?]/) { |char| "[#{char}]" }
        end
      end
    end
  end
end
