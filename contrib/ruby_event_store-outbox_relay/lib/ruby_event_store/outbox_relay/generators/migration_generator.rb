# frozen_string_literal: true

require "erb"

module RubyEventStore
  module OutboxRelay
    class MigrationGenerator
      include ActiveRecord::MigrationGeneratorMethods

      TEMPLATE_DIRECTORY_BY_ADAPTER = { "postgresql" => "postgres", "mysql2" => "mysql", "sqlite" => "sqlite" }.freeze

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
        template(database_adapter).result_with_hash(migration_version: migration_version)
      end

      def template(database_adapter)
        directory = TEMPLATE_DIRECTORY_BY_ADAPTER.fetch(database_adapter.adapter_name)
        migration_template(File.join(__dir__, "templates", directory), "add_published_at_to_event_store_events")
      end

      def build_path(migration_path)
        File.join(migration_path.to_s, "#{timestamp}_add_published_at_to_event_store_events.rb")
      end
    end
  end
end
