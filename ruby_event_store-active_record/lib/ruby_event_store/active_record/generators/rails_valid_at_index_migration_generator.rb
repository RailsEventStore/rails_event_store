# frozen_string_literal: true

begin
  require "rails/generators"
rescue LoadError
end

if defined?(Rails::Generators::Base)
  module RubyEventStore
    module ActiveRecord
      class RailsValidAtIndexMigrationGenerator < Rails::Generators::Base
        class Error < Thor::Error
        end

        namespace "ruby_event_store:active_record:migration_for_valid_at_index"

        source_root File.expand_path(File.join(File.dirname(__FILE__), "../generators/templates"))

        def initialize(*args)
          super

          @database_adapter = DatabaseAdapter.from_string(adapter_name)
        rescue UnsupportedAdapter => e
          raise Error, e.message
        end

        include RailsGeneratorMethods

        def create_migration
          template "#{@database_adapter.template_directory}add_valid_at_index_to_event_store_events_template.erb",
                   "db/migrate/#{timestamp}_add_valid_at_index_to_event_store_events.rb"
        end
      end
    end
  end
end
