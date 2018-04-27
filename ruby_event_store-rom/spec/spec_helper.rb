require 'ruby_event_store/rom'
require 'support/rspec_defaults'
require 'support/mutant_timeout'
require 'dry/inflector'

ENV['DATABASE_URL'] ||= 'sqlite:db.sqlite3'
ENV['ROM_ADAPTER'] ||= 'SQL'

adapter_name = Dry::Inflector.new.underscore(ENV['ROM_ADAPTER']).to_sym

require "ruby_event_store/rom/#{adapter_name}"
ADAPTER_MODULE = Kernel.const_get("RubyEventStore::ROM::#{ENV['ROM_ADAPTER']}")

rom = ROM::Configuration.new(
  adapter_name, # :sql, :memory
  ENV['DATABASE_URL'],
  max_connections: ENV['DATABASE_URL'] =~ /sqlite/ ? 1 : 5,
  preconnect: :concurrently,
  # sql_mode: %w[NO_AUTO_VALUE_ON_ZERO STRICT_ALL_TABLES]
)
# $stdout.sync = true
# rom.default.use_logger Logger.new(STDOUT)
rom.default.run_migrations if adapter_name == :sql

RubyEventStore::ROM.env = RubyEventStore::ROM.setup(rom)

module SchemaHelper
  def rom_helper
    ADAPTER_MODULE::SpecHelper.new(rom: env)
  end

  def env
    RubyEventStore::ROM.env
  end

  def container
    env.container
  end

  def rom_db
    container.gateways[:default]
  end

  def establish_database_connection
    rom_helper.establish_gateway_connection
  end

  def load_database_schema
    rom_helper.load_gateway_schema
  end

  def drop_database
    rom_helper.drop_gateway_schema
  end

  # See: https://github.com/rom-rb/rom-sql/blob/master/spec/shared/database_setup.rb
  def close_database_connection
    rom_helper.close_gateway_connection
  end

  def has_connection_pooling?
    rom_helper.has_connection_pooling?
  end

  def connection_pool_size
    rom_helper.connection_pool_size
  end

  def close_pool_connection
    rom_helper.close_pool_connection
  end
end

RSpec.configure do |config|
  config.failure_color = :magenta
end
