# frozen_string_literal: true

begin
  require 'rails/generators'
rescue LoadError
end

module RailsEventStoreActiveRecord
  class MigrationGenerator < Rails::Generators::Base
    class Error < Thor::Error; end

    DATA_TYPES = %w(binary json jsonb).freeze

    source_root File.expand_path(File.join(File.dirname(__FILE__), '../generators/templates'))
    class_option(
      :data_type,
      type: :string,
      default: 'binary',
      desc: "Configure the data type for `data` and `meta data` feilds in Postgres migration (options: #{DATA_TYPES.join('/')})"
    )

    def initialize(*args)
      super

      if DATA_TYPES.exclude?(options.fetch(:data_type))
        raise Error, "Invalid value for --data-type option. Supported for options are: #{DATA_TYPES.join(", ")}."
      end
    end

    def create_migration
      template "create_event_store_events_template.rb", "db/migrate/#{timestamp}_create_event_store_events.rb"
    end

    private

    def data_type
      options.fetch('data_type')
    end

    def rails_version
      Rails::VERSION::STRING
    end

    def migration_version
      return nil if Gem::Version.new(rails_version) < Gem::Version.new("5.0.0")
      "[4.2]"
    end

    def timestamp
      Time.now.strftime("%Y%m%d%H%M%S")
    end
  end
end if defined?(Rails::Generators::Base)