# frozen_string_literal: true

begin
  require "rails/generators"
rescue LoadError
end

if defined?(Rails::Generators::Base)
  module RubyEventStore
    module Outbox
      class MigrationGenerator < Rails::Generators::Base
        source_root File.expand_path(File.join(File.dirname(__FILE__), "./templates"))

        def create_migration
          template "create_event_store_outbox_template.rb", "db/migrate/#{timestamp}_create_event_store_outbox.rb"
        end

        private

        def migration_version
          "[4.2]"
        end

        def timestamp
          Time.now.strftime("%Y%m%d%H%M%S")
        end
      end
    end
  end
end
