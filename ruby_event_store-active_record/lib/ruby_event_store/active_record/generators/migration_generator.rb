# frozen_string_literal: true

require "erb"

module RubyEventStore
  module ActiveRecord
    class MigrationGenerator
      def call(database_adapter, migration_path)
        migration_code = migration_code(database_adapter)
        path = build_path(migration_path)
        write_to_file(migration_code, path)
        path
      end

      private

      def absolute_path(path)
        File.expand_path(path, __dir__)
      end

      def migration_code(database_adapter)
        migration_template(template_root(database_adapter), "create_event_store_events").result_with_hash(
          migration_version: migration_version,
          data_type: database_adapter.data_type,
        )
      end

      def template_root(database_adapter)
        absolute_path("./templates/#{database_adapter.template_directory}")
      end

      def migration_template(template_root, name)
        ERB.new(File.read(File.join(template_root, "#{name}_template.erb")))
      end

      def migration_version
        ::ActiveRecord::Migration.current_version
      end

      def timestamp
        Time.now.strftime("%Y%m%d%H%M%S")
      end

      def write_to_file(migration_code, path)
        File.write(path, migration_code)
      end

      def build_path(migration_path)
        File.join("#{migration_path}", "#{timestamp}_create_event_store_events.rb")
      end
    end
  end
end
