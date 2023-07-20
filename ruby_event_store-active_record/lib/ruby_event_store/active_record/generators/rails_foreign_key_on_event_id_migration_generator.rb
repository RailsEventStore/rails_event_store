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

          VerifyAdapter.new.call(adapter)
        rescue UnsupportedAdapter => e
          raise Error, e.message
        end

        def create_migration
          case adapter
          when 'postgresql'
            template "#{template_directory}add_foreign_key_on_event_id_to_event_store_events_in_streams_template.erb",
                     "db/migrate/#{timestamp}_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb"
            template "#{template_directory}validate_add_foreign_key_on_event_id_to_event_store_events_in_streams_template.erb",
                     "db/migrate/#{timestamp}_validate_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb"
          else
            template "#{template_directory}add_foreign_key_on_event_id_to_event_store_events_in_streams_template.erb",
                     "db/migrate/#{timestamp}_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb"
          end
        end

        private

        def adapter
          ::ActiveRecord::Base.connection.adapter_name.downcase
        end

        def migration_version
          ::ActiveRecord::Migration.current_version
        end

        def timestamp
          Time.now.strftime("%Y%m%d%H%M%S")
        end

        def template_directory
          TemplateDirectory.for_adapter(adapter)
        end
      end
    end
  end
end
