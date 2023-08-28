# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class DatabaseAdapter
      def initialize(adapter_name)
        @adapter_name = adapter_name.eql?("postgis") ? "postgresql" : adapter_name
      end

      attr_reader :adapter_name

      Postgres = new("postgresql")
      MySQL = new("mysql")
      Sqlite = new("sqlite")

      def eql?(other)
        other.instance_of?(DatabaseAdapter) && adapter_name.eql?(other.adapter_name)
      end

      alias == eql?
    end
  end
end