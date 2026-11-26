# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class StreamsMetadataMigrationGenerator
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
        migration_template(absolute_path("./templates"), "create_event_store_streams_metadata").result_with_hash(
          migration_version: migration_version,
        )
      end

      def build_path(migration_path)
        File.join("#{migration_path}", "#{timestamp}_create_event_store_streams_metadata.rb")
      end
    end
  end
end
