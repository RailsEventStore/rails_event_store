# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class TemplateDirectory
      def self.for_adapter(database_adapter)
        case database_adapter.downcase
        when "postgresql"
          "postgres/"
        when "mysql2"
          "mysql/"
        end
      end
    end
  end
end
