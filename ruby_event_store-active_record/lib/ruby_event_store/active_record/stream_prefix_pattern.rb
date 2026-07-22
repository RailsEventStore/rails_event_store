# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    # SQLite's LIKE is case-insensitive by default and only uses the index when the
    # column's collation matches the case_sensitive_like pragma. GLOB doesn't have that
    # problem, so SQLite gets its own strategy here.
    #
    # PostgreSQL cannot turn LIKE 'prefix%' into an index range scan under a linguistic
    # collation (values sharing a prefix are not contiguous in such ordering), so every
    # hop would degrade to filtering an ordered index scan -- reading up to the whole
    # index per search. The search is therefore only available once the byte-ordered
    # index on (stream COLLATE "C") is present, and the hops are spelled with
    # COLLATE "C" to match it. The index is looked up on each search so that adding it
    # does not require a process restart.
    class StreamPrefixPattern
      def self.for(stream_klass)
        adapter_name = stream_klass.connection.adapter_name
        if adapter_name.match?(/sqlite/i)
          Glob.new
        elsif adapter_name.match?(/postgres/i)
          CollateC.new if c_collation_index?(stream_klass)
        else
          Like.new
        end
      end

      def self.c_collation_index?(stream_klass)
        connection = stream_klass.connection
        !connection.select_value(<<~SQL, "SCHEMA").nil?
          SELECT true
          FROM pg_index i
          JOIN pg_class t ON t.oid = i.indrelid
          JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = i.indkey[0]
          JOIN pg_collation c ON c.oid = i.indcollation[0]
          WHERE t.relname = #{connection.quote(stream_klass.table_name)}
            AND a.attname = 'stream'
            AND c.collname IN ('C', 'POSIX')
        SQL
      end
      private_class_method :c_collation_index?

      class Like
        def condition
          "stream LIKE ?"
        end

        # No explicit ESCAPE clause: both adapters already default to backslash, and an
        # explicit ESCAPE '\' literal is spelled differently on each and breaks on MySQL.
        def bind_value(prefix)
          "#{::ActiveRecord::Base.sanitize_sql_like(prefix)}%"
        end

        def cursor_condition
          "stream > ?"
        end

        def order
          :stream
        end
      end

      class CollateC < Like
        def condition
          %{stream COLLATE "C" LIKE ?}
        end

        def cursor_condition
          %{stream COLLATE "C" > ?}
        end

        def order
          Arel.sql(%{stream COLLATE "C" ASC})
        end
      end

      class Glob
        def condition
          "stream GLOB ?"
        end

        def bind_value(prefix)
          "#{escape(prefix)}*"
        end

        def cursor_condition
          "stream > ?"
        end

        def order
          :stream
        end

        private

        def escape(string)
          string.gsub(/[\[*?]/) { |char| "[#{char}]" }
        end
      end
    end
  end
end
