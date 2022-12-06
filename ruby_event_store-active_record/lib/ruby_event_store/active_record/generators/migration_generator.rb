# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class MigrationGenerator
      DATA_TYPES = %w[binary json jsonb].freeze

      def call(data_type, migration_path)
        raise ArgumentError, "Invalid value for --data-type option. Supported for options are: #{DATA_TYPES.join(", ")}." unless DATA_TYPES.include?(data_type)

        migration_code = migration_code(data_type)
        path = build_path(migration_path)
        write_to_file(migration_code, path)
        path
      end

      private

      def migration_code(data_type)
        migration_template(File.expand_path("./templates", __dir__), "create_event_store_events").result_with_hash(migration_version: migration_version, data_type: data_type)
      end

      def migration_template(template_root, name)
        ERB.new(File.read(File.join(template_root, "#{name}_template.erb")))
      end

      def migration_version
        "[4.2]"
      end

      def timestamp
        Time.now.strftime("%Y%m%d%H%M%S")
      end

      def write_to_file(migration_code, path)
        open(path, 'w') do |file|
          file.write(migration_code)
        end
      end

      def build_path(migration_path)
        File.expand_path(File.join(__dir__, "../../../../", "#{migration_path}", "#{timestamp}_create_event_store_events.rb"))
      end
    end
  end
end
