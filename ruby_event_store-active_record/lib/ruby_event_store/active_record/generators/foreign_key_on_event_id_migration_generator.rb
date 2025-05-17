# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class ForeignKeyOnEventIdMigrationGenerator
      def call(database_adapter, migration_path)
        time = Time.now
        each_migration(database_adapter) do |migration_name, i|
          path = build_path(migration_path, migration_name, time + i)
          write_to_file(path, migration_code(database_adapter, migration_name))
        end
      end

      private

      def each_migration(database_adapter, &block)
        case database_adapter
        when DatabaseAdapter::PostgreSQL
          %w[
            add_foreign_key_on_event_id_to_event_store_events_in_streams
            validate_add_foreign_key_on_event_id_to_event_store_events_in_streams
          ]
        else
          ["add_foreign_key_on_event_id_to_event_store_events_in_streams"]
        end.each.with_index(&block)
      end

      def absolute_path(path)
        File.expand_path(path, __dir__)
      end

      def migration_code(database_adapter, migration_name)
        migration_template(template_root(database_adapter), migration_name).result_with_hash(
          migration_version: migration_version,
        )
      end

      def migration_template(template_root, name)
        ERB.new(File.read(File.join(template_root, "#{name}_template.erb")))
      end

      def template_root(database_adapter)
        absolute_path("./templates/#{database_adapter.template_directory}")
      end

      def migration_version
        ::ActiveRecord::Migration.current_version
      end

      def write_to_file(path, migration_code)
        File.write(path, migration_code)
      end

      def build_path(migration_path, migration_name, time)
        File.join("#{migration_path}", "#{migration_verion_number(time)}_#{migration_name}.rb")
      end

      def migration_verion_number(time)
        time.strftime("%Y%m%d%H%M%S")
      end
    end
  end
end
