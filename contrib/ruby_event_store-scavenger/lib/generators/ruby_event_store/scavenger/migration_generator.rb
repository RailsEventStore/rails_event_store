# frozen_string_literal: true

begin
  require "rails/generators"
rescue LoadError
end

if defined?(Rails::Generators::Base)
  require "ruby_event_store/scavenger/migration_generator"

  module RubyEventStore
    module Scavenger
      class RailsMigrationGenerator < Rails::Generators::Base
        namespace "ruby_event_store:scavenger:migration"

        def create_migration
          create_file "db/migrate/#{Time.now.strftime("%Y%m%d%H%M%S")}_#{MigrationGenerator::NAME}.rb",
                      MigrationGenerator.new.migration_code
        end
      end
    end
  end
end
