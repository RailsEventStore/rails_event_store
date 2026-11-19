# frozen_string_literal: true

begin
  require "rails/generators"
rescue LoadError
end

if defined?(Rails::Generators::Base)
  module RubyEventStore
    module ActiveRecord
      class RailsStreamsMetadataMigrationGenerator < Rails::Generators::Base
        class Error < Thor::Error
        end

        namespace "ruby_event_store:active_record:migration_for_streams_metadata"

        source_root File.expand_path(File.join(File.dirname(__FILE__), "../generators/templates"))

        include RailsGeneratorMethods

        def create_migration
          template "create_event_store_streams_metadata_template.erb",
                   "db/migrate/#{timestamp}_create_event_store_streams_metadata.rb"
        end
      end
    end
  end
end
