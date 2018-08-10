begin
  require 'rails/generators'
rescue LoadError
end

module RailsEventStoreActiveRecord
  class MigrationGenerator < Rails::Generators::Base
    source_root File.expand_path(File.join(File.dirname(__FILE__), '../generators/templates'))

    def create_migration
      template "migration_template.rb", "db/migrate/#{timestamp}_create_event_store_events.rb"
    end

    private

    def rails_version
      Rails::VERSION::STRING
    end

    def migration_version
      return nil if Gem::Version.new(rails_version) < Gem::Version.new('5.0.0')

      rails_version_with_subnumber = rails_version.match(/\d\.\d/)[0]
      "[#{rails_version_with_subnumber}]"
    end

    def timestamp
      Time.now.strftime("%Y%m%d%H%M%S")
    end
  end
end if defined?(Rails::Generators::Base)
