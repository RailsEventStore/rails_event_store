# frozen_string_literal: true

require "erb"

module RubyEventStore
  module ActiveRecord
    class MigrationGenerator
      include MigrationGeneratorMethods

      def call(database_adapter, migration_path)
        path, content = generate(database_adapter, migration_path)
        File.write(path, content)
        path
      end

      def generate(database_adapter, migration_path)
        [build_path(migration_path), migration_code(database_adapter)]
      end

      private

      def migration_code(database_adapter)
        migration_template(template_root(database_adapter), "create_event_store_events").result_with_hash(
          migration_version: migration_version,
          data_type: database_adapter.data_type,
        )
      end

      def build_path(migration_path)
        File.join("#{migration_path}", "#{timestamp}_create_event_store_events.rb")
      end
    end
  end
end
