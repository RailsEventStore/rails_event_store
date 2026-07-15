# frozen_string_literal: true

begin
  require "rails/generators"
rescue LoadError
end

if defined?(Rails::Generators::Base)
  module RubyEventStore
    module ActiveRecord
      class RailsStreamIdIndexMigrationGenerator < Rails::Generators::Base
        class Error < Thor::Error
        end

        namespace "ruby_event_store:active_record:migration_for_missing_stream_id_index"

        source_root File.expand_path(File.join(File.dirname(__FILE__), "../generators/templates"))

        def initialize(*args)
          super

          @database_adapter = DatabaseAdapter.from_string(adapter_name)
        rescue UnsupportedAdapter => e
          raise Error, e.message
        end

        def create_migration
          template "#{@database_adapter.template_directory}add_stream_id_index_to_event_store_events_in_streams_template.erb",
                   "db/migrate/#{timestamp}_add_stream_id_index_to_event_store_events_in_streams.rb"
        end

        private

        def adapter_name
          ::ActiveRecord::Base.connection.adapter_name
        end

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
