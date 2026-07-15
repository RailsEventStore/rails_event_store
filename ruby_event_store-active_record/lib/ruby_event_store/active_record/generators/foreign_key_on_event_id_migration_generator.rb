# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class ForeignKeyOnEventIdMigrationGenerator
      include MigrationGeneratorMethods

      def call(database_adapter, migration_path)
        generate(database_adapter, migration_path).each do |path, content|
          File.write(path, content)
        end
      end

      def generate(database_adapter, migration_path)
        time = Time.now
        migration_names(database_adapter).map.with_index do |migration_name, i|
          [
            build_path(migration_path, migration_name, time + i),
            migration_code(database_adapter, migration_name),
          ]
        end
      end

      private

      def migration_names(database_adapter)
        case database_adapter
        when DatabaseAdapter::PostgreSQL
          %w[
            add_foreign_key_on_event_id_to_event_store_events_in_streams
            validate_add_foreign_key_on_event_id_to_event_store_events_in_streams
          ]
        else
          ["add_foreign_key_on_event_id_to_event_store_events_in_streams"]
        end
      end

      def migration_code(database_adapter, migration_name)
        migration_template(template_root(database_adapter), migration_name).result_with_hash(
          migration_version: migration_version,
        )
      end

      def build_path(migration_path, migration_name, time)
        File.join("#{migration_path}", "#{timestamp(time)}_#{migration_name}.rb")
      end
    end
  end
end
