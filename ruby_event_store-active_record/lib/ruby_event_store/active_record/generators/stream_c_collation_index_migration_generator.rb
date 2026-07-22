# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class StreamCCollationIndexMigrationGenerator
      include MigrationGeneratorMethods

      def call(migration_path)
        path, content = generate(migration_path)
        File.write(path, content)
        path
      end

      def generate(migration_path)
        [build_path(migration_path), migration_code]
      end

      private

      def migration_code
        migration_template(
          absolute_path("./templates/postgres"),
          "add_stream_c_collation_index_to_event_store_events_in_streams",
        ).result_with_hash(migration_version: migration_version)
      end

      def build_path(migration_path)
        File.join(
          "#{migration_path}",
          "#{timestamp}_add_stream_c_collation_index_to_event_store_events_in_streams.rb",
        )
      end
    end
  end
end
