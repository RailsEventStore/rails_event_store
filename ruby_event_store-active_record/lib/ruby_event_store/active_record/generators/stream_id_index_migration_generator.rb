# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class StreamIdIndexMigrationGenerator
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
        migration_template(database_adapter).result_with_hash(migration_version: migration_version)
      end

      def migration_template(database_adapter)
        ERB.new(
          File.read(
            File.join(template_root(database_adapter), "add_stream_id_index_to_event_store_events_in_streams_template.erb"),
          ),
        )
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
        File.join("#{migration_path}", "#{timestamp}_add_stream_id_index_to_event_store_events_in_streams.rb")
      end
    end
  end
end