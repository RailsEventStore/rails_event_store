require 'ruby_event_store_rom_sql'
require 'support/rspec_defaults'

begin
  require 'pry'
  require 'pry-byebug'
rescue LoadError
end

ENV['DATABASE_URL']  ||= 'sqlite:db.sqlite3'

config = ROM::Configuration.new(:sql, ENV['DATABASE_URL'])
# # See: https://github.com/rom-rb/rom-sql/blob/master/spec/unit/relation/instrument_spec.rb
# config.plugin(:sql, relations: :instrumentation) do |c|
#   c.notifications = Instrumenter
# end

config.default.run_migrations

RubyEventStoreRomSql.env = RubyEventStoreRomSql.setup(config)

module SchemaHelper
  def rom
    RubyEventStoreRomSql.env
  end

  def rom_db
    rom.gateways[:default]
  end

  def establish_database_connection
  end

  def load_database_schema
    RubyEventStoreRomSql.run_migrations_for(rom_db)
  end

  def drop_database
    rom_db.connection.drop_table?('event_store_events')
    rom_db.connection.drop_table?('event_store_events_in_streams')
    rom_db.connection.drop_table?('schema_migrations')
  end

  # See: https://github.com/rom-rb/rom-sql/blob/master/spec/shared/database_setup.rb
  def close_database_connection
    rom_db.connection.disconnect
    # Prevent the auto-reconnect when the test completed
    # This will save from hardly reproducible connection run outs
    rom_db.connection.pool.available_connections.freeze
  end
end

RSpec.configure do |config|
  config.failure_color = :magenta
end
