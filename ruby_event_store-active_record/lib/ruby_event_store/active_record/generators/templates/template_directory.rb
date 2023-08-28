# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class TemplateDirectory
      def self.for_adapter(database_adapter)
        case database_adapter
        when DatabaseAdapter::PostgreSQL
          "postgres/"
        when DatabaseAdapter::MySQL2
          "mysql/"
        end
      end
    end
  end
end
