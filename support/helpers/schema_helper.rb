# frozen_string_literal: true

require_relative "migrator"
require_relative "subprocess_helper"

module SchemaHelper
  include SubprocessHelper

  def run_migration(name)
    m = Migrator.new(File.expand_path(template_path, __dir__))
    m.run_migration(name)
  end

  def establish_database_connection
    ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])
  end

  def close_database_connection
    ActiveRecord::Base.remove_connection
  end

  def load_database_schema
    run_migration("create_event_store_events")
  end

  def drop_database
    ActiveRecord::Migration.drop_table("event_store_events_in_streams")
    ActiveRecord::Migration.drop_table("event_store_events")
  rescue ::ActiveRecord::StatementInvalid
  end

  def dump_schema
    schema = StringIO.new
    ActiveRecord::SchemaDumper.dump(::ActiveRecord::Base.connection, schema)
    schema.rewind
    schema.read
  end

  private

  def template_path
    "../../ruby_event_store-active_record/lib/ruby_event_store/active_record/generators/templates/#{template_directory}"
  end

  def template_directory
    return "postgres" if postgres?
    return "mysql" if mysql?
  end

  def sqlite?
    ENV["DATABASE_URL"].include?("sqlite")
  end

  def mysql?
    ENV["DATABASE_URL"].include?("mysql2")
  end

  def postgres?
    ENV["DATABASE_URL"].include?("postgres")
  end
end
