# frozen_string_literal: true

begin
  require "rails/generators"
rescue LoadError
end

if defined?(Rails::Generators::Base)
  module RubyEventStore
    module ActiveRecord
      class RailsStreamCCollationIndexMigrationGenerator < Rails::Generators::Base
        class Error < Thor::Error
        end

        namespace "ruby_event_store:active_record:migration_for_stream_c_collation_index"

        source_root File.expand_path(File.join(File.dirname(__FILE__), "../generators/templates"))

        def initialize(*args)
          super

          @database_adapter = DatabaseAdapter.from_string(adapter_name)
          unless @database_adapter.is_a?(DatabaseAdapter::PostgreSQL)
            raise Error,
                  "The stream COLLATE \"C\" index is only applicable to PostgreSQL, adapter in use: #{adapter_name.inspect}"
          end
        rescue UnsupportedAdapter => e
          raise Error, e.message
        end

        include RailsGeneratorMethods

        def create_migration
          template "#{@database_adapter.template_directory}add_stream_c_collation_index_to_event_store_events_in_streams_template.erb",
                   "db/migrate/#{timestamp}_add_stream_c_collation_index_to_event_store_events_in_streams.rb"
        end
      end
    end
  end
end
