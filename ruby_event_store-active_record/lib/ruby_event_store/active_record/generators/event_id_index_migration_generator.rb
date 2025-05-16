# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class EventIdIndexMigrationGenerator
      def call(migration_path)
        path = build_path(migration_path)
        write_to_file(path)
        path
      end

      private

      def absolute_path(path)
        File.expand_path(path, __dir__)
      end

      def migration_code
        migration_template.result_with_hash(migration_version: migration_version)
      end

      def migration_template
        ERB.new(
          File.read(
            File.join(absolute_path("./templates"), "add_event_id_index_to_event_store_events_in_streams_template.erb"),
          ),
        )
      end

      def migration_version
        ::ActiveRecord::Migration.current_version
      end

      def timestamp
        Time.now.strftime("%Y%m%d%H%M%S")
      end

      def write_to_file(path)
        File.write(path, migration_code)
      end

      def build_path(migration_path)
        File.join("#{migration_path}", "#{timestamp}_add_event_id_index_to_event_store_events_in_streams.rb")
      end
    end
  end
end
