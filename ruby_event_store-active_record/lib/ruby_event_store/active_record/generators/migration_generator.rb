# frozen_string_literal: true
require_relative "../../../../../support/helpers/migrator"

module RubyEventStore
  module ActiveRecord
    class MigrationGenerator
      DATA_TYPES = %w[binary json jsonb].freeze

      def call(data_type, migration_path: "db/migrate")
        raise ArgumentError, "Invalid value for --data-type option. Supported for options are: #{DATA_TYPES.join(", ")}." unless DATA_TYPES.include?(data_type)

        migration_code = migration_code(data_type)
        path = build_path(migration_path)
        write_to_file(migration_code, path)
        path
      end

      private

      def migration_code(data_type)
        Migrator.new(
          File.expand_path(
            "./templates",
            __dir__
          )
        ).migration_code("create_event_store_events", data_type: data_type)
      end

      def timestamp
        Time.now.strftime("%Y%m%d%H%M%S")
      end

      def write_to_file(migration_code, path)
        open(path, 'w') do |file|
          file.write <<-EOF
#{migration_code}
          EOF
        end
      end

      def build_path(migration_path)
        File.expand_path(File.join(__dir__, "../../../../", "#{migration_path}", "#{timestamp}_create_event_store_events.rb"))
      end
    end
  end
end
