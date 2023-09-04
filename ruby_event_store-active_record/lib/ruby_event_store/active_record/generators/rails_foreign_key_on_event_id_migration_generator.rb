# frozen_string_literal: true

begin
  require "rails/generators"
rescue LoadError
end

if defined?(Rails::Generators::Base)
  module RubyEventStore
    module ActiveRecord
      class RailsForeignKeyOnEventIdMigrationGenerator < Rails::Generators::Base
        class Error < Thor::Error
        end

        namespace "rails_event_store_active_record:migration_for_foreign_key_on_event_id"

        source_root File.expand_path(File.join(File.dirname(__FILE__), "../generators/templates"))

        def initialize(*args)
          super

          @database_adapter = DatabaseAdapter.from_string(adapter_name)
        rescue UnsupportedAdapter => e
          raise Error, e.message
        end

        def create_migration
          case @database_adapter
          when DatabaseAdapter::PostgreSQL
            time = Time.now
            template "#{@database_adapter.template_directory}add_foreign_key_on_event_id_to_event_store_events_in_streams_template.erb",
                     "db/migrate/#{migration_verion_number(time)}_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb"
            template "#{@database_adapter.template_directory}validate_add_foreign_key_on_event_id_to_event_store_events_in_streams_template.erb",
                     "db/migrate/#{migration_verion_number(time + 1)}_validate_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb"
          else
            template "#{@database_adapter.template_directory}add_foreign_key_on_event_id_to_event_store_events_in_streams_template.erb",
                     "db/migrate/#{migration_verion_number(Time.now)}_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb"
          end
        end

        private

        def adapter_name
          ::ActiveRecord::Base.connection.adapter_name
        end

        def migration_version
          ::ActiveRecord::Migration.current_version
        end

        def migration_verion_number(time)
          time.strftime("%Y%m%d%H%M%S")
        end
      end
    end
  end
end
