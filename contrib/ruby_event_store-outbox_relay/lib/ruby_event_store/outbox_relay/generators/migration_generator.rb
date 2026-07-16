# frozen_string_literal: true

require "erb"

module RubyEventStore
  module OutboxRelay
    class MigrationGenerator
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
        template.result_with_hash(migration_version: migration_version)
      end

      def template
        ERB.new(File.read(File.join(__dir__, "templates", "add_published_at_to_event_store_events_template.erb")))
      end

      def migration_version
        ::ActiveRecord::Migration.current_version
      end

      def build_path(migration_path)
        File.join(migration_path.to_s, "#{timestamp}_add_published_at_to_event_store_events.rb")
      end

      def timestamp(time = Time.now)
        time.strftime("%Y%m%d%H%M%S")
      end
    end
  end
end
