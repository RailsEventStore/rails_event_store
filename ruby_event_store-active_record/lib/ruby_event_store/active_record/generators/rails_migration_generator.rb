# frozen_string_literal: true

begin
  require "rails/generators"
rescue LoadError
end

module RubyEventStore
  module ActiveRecord
    class RailsMigrationGenerator < Rails::Generators::Base
      class Error < Thor::Error
      end

      DATA_TYPES = %w[binary json jsonb].freeze

      namespace "rails_event_store_active_record:migration"

      source_root File.expand_path(File.join(File.dirname(__FILE__), "../generators/templates"))
      class_option(
        :data_type,
        type: :string,
        default: "binary",
        desc:
          "Configure the data type for `data` and `meta data` fields in Postgres migration (options: #{DATA_TYPES.join("/")})"
      )

      def initialize(*args)
        super

        if DATA_TYPES.exclude?(data_type)
          raise Error, "Invalid value for --data-type option. Supported for options are: #{DATA_TYPES.join(", ")}."
        end

        VerifyDataTypeForAdapter.new.call(adapter, data_type)
      rescue StandardError => e
        raise Error, e.message
      end

      def create_migration
        template "#{template_directory}create_event_store_events_template.erb", "db/migrate/#{timestamp}_create_event_store_events.rb"
      end

      private

      def template_directory
        TemplateDirectory.for_adapter(adapter)
      end

      def data_type
        options.fetch("data_type")
      end

      def adapter
        ::ActiveRecord::Base.connection.adapter_name.downcase
      end

      def migration_version
        ::ActiveRecord::Migration.current_version
      end

      def timestamp
        Time.now.strftime("%Y%m%d%H%M%S")
      end
    end
  end
end if defined?(Rails::Generators::Base)
