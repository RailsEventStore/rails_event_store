# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class ValidAtIndexMigrationGenerator
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
        migration_template(template_root(database_adapter), "add_valid_at_index_to_event_store_events").result_with_hash(
          migration_version: migration_version,
        )
      end

      def build_path(migration_path)
        File.join("#{migration_path}", "#{timestamp}_add_valid_at_index_to_event_store_events.rb")
      end
    end
  end
end
