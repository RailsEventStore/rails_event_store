require_relative 'migrator'
require_relative 'subprocess_helper'


module SchemaHelper
  include SubprocessHelper

  def run_migration(name)
    m = Migrator.new(File.expand_path('../../rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates', __dir__))
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
  rescue ActiveRecord::StatementInvalid
  end

  def dump_schema
    schema = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, schema)
    schema.rewind
    schema.read
  end

  def build_schema(gemfile, template_name: nil)
    run_in_subprocess(<<~EOF, gemfile: gemfile)
      require 'rails_event_store_active_record'
      require 'ruby_event_store'
      require 'logger'
      require '../support/helpers/migrator'

      $verbose = ENV.has_key?('VERBOSE') ? true : false
      ActiveRecord::Schema.verbose = $verbose
      ActiveRecord::Base.logger    = Logger.new(STDOUT) if $verbose
      ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

      gem_path = $LOAD_PATH.find { |path| path.match(/rails_event_store_active_record/) }
      Migrator.new(File.expand_path('rails_event_store_active_record/generators/templates', gem_path))
        .run_migration('create_event_store_events', #{template_name ? "'#{template_name}'" : "nil"})
    EOF
  end

  def run_code(code, gemfile:)
    run_in_subprocess(<<~EOF, gemfile: gemfile)
      require 'rails_event_store_active_record'
      require 'ruby_event_store'
      require 'logger'

      $verbose = ENV.has_key?('VERBOSE') ? true : false
      ActiveRecord::Schema.verbose = $verbose
      ActiveRecord::Base.logger    = Logger.new(STDOUT) if $verbose
      ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

      #{code}
    EOF
  end

  def validate_migration(source_gemfile, target_gemfile,
                         source_template_name: nil)
    begin
      build_schema(source_gemfile, template_name: source_template_name)
      establish_database_connection
      yield
      actual_schema = dump_schema
      drop_database
      close_database_connection
      build_schema(target_gemfile)
      establish_database_connection
      expect(actual_schema).to eq(dump_schema)
    ensure
      drop_database
    end
  end
end
