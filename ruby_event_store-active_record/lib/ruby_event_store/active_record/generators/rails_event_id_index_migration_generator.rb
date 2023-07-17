# frozen_string_literal: true

begin
  require "rails/generators"
rescue LoadError
end

if defined?(Rails::Generators::Base)
  module RubyEventStore
    module ActiveRecord
      class RailsEventIdIndexMigrationGenerator < Rails::Generators::Base
        class Error < Thor::Error
        end

        namespace "rails_event_store_active_record:migration_for_missing_event_id_index"

        source_root File.expand_path(File.join(File.dirname(__FILE__), "../generators/templates"))

        def create_migration
          template "add_event_id_index_to_event_store_events_in_streams_template.erb",
                   "db/migrate/#{timestamp}_add_event_id_index_to_event_store_events_in_streams.rb"
        end

        private

        def migration_version
          ::ActiveRecord::Migration.current_version
        end

        def timestamp
          Time.now.strftime("%Y%m%d%H%M%S")
        end
      end
    end
  end
end
