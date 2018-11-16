require_relative 'migrator'
require_relative 'subprocess_helper'


module SchemaHelper
  include SubprocessHelper

  def run_migration(name)
    m = Migrator.new(File.expand_path('../rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates', __dir__))
    m.run_migration(name)
  end

  def establish_database_connection
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
  end

  def close_database_connection
    ActiveRecord::Base.remove_connection
  end

  def load_database_schema
    run_migration('create_event_store_events')
  end

  def drop_database
    ActiveRecord::Migration.drop_table("event_store_events")
    ActiveRecord::Migration.drop_table("event_store_events_in_streams")
  end

  def load_legacy_database_schema
    run_in_subprocess(<<~EOF, gemfile: 'Gemfile.0_18_2')
      require 'rails/generators'
      require 'rails_event_store_active_record'
      require 'ruby_event_store'
      require 'logger'
      require '../lib/migrator'

      $verbose = ENV.has_key?('VERBOSE') ? true : false
      ActiveRecord::Schema.verbose = $verbose
      ActiveRecord::Base.logger    = Logger.new(STDOUT) if $verbose
      ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

      gem_path = $LOAD_PATH.find { |path| path.match(/rails_event_store_active_record/) }
      Migrator.new(File.expand_path('rails_event_store_active_record/generators/templates', gem_path))
        .run_migration('create_event_store_events', 'migration')
    EOF
    reset_schema_cache
  end

  def drop_legacy_database
    ActiveRecord::Migration.drop_table("event_store_events")
  end

  def reset_schema_cache
    RailsEventStoreActiveRecord::Event.connection.schema_cache.clear!
    RailsEventStoreActiveRecord::Event.reset_column_information
  end
end
