# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class ValidAtIndexMigrationGenerator
      def call(database_adapter, migration_path)
        path, content = generate(database_adapter, migration_path)
        File.write(path, content)
        path
      end

      def generate(database_adapter, migration_path)
        [build_path(migration_path), migration_code(database_adapter)]
      end

      private

      def absolute_path(path)
        File.expand_path(path, __dir__)
      end

      def migration_code(database_adapter)
        migration_template(template_root(database_adapter), "add_valid_at_index_to_event_store_events").result_with_hash(
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

      def timestamp
        Time.now.strftime("%Y%m%d%H%M%S")
      end

      def build_path(migration_path)
        File.join("#{migration_path}", "#{timestamp}_add_valid_at_index_to_event_store_events.rb")
      end
    end
  end
end
