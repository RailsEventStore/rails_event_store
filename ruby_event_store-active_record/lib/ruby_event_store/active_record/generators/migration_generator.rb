# frozen_string_literal: true
require "erb"

module RubyEventStore
  module ActiveRecord
    class MigrationGenerator
      DATA_TYPES = %w[binary json jsonb].freeze

      def call(data_type, migration_path)
        raise ArgumentError, "Invalid value for data type. Supported for options are: #{DATA_TYPES.join(", ")}." unless DATA_TYPES.include?(data_type)

        migration_code = migration_code(data_type)
        path = build_path(migration_path)
        write_to_file(migration_code, path)
        path
      end

      private

      def absolute_path(path)
        File.expand_path(path, __dir__)
      end

      def migration_code(data_type)
        ::ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])
        postgres = ::ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        migration_template(absolute_path("./templates#{postgres ? "/postgres" : ""}"), "create_event_store_events").result_with_hash(migration_version: migration_version, data_type: data_type)
      end

      def migration_template(template_root, name)
        ERB.new(File.read(File.join(template_root, "#{name}_template.erb")))
      end

      def migration_version
        "[#{::ActiveRecord::Migration.current_version}]"
      end

      def timestamp
        Time.now.strftime("%Y%m%d%H%M%S")
      end

      def write_to_file(migration_code, path)
        File.write(path, migration_code)
      end

      def build_path(migration_path)
        File.join( "#{migration_path}", "#{timestamp}_create_event_store_events.rb")
      end
    end
  end
end
