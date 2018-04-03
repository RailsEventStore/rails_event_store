require 'ruby_event_store_rom_sql/event_repository'
require 'ruby_event_store_rom_sql/index_violation_detector'
require 'ruby_event_store_rom_sql/version'
require 'rom/sql'
require 'rom-repository'
require 'rom-changeset'

module RubyEventStoreRomSql
  class << self
    # Set to a default instance
    attr_accessor :env

    def configure(database_uri = ENV['DATABASE_URL'], &block)
      if database_uri.is_a?(::ROM::Configuration)
        # Call config block manually
        ::ROM.container(database_uri.tap(&block), &block)
      else
        ::ROM.container(:sql, database_uri, &block)
      end
    end

    def setup(*args, &block)
      configure(*args) do |config|
        apply_defaults(config)

        block.call(config) if block
      end
    end

    # ROM::Configuration
    def apply_defaults(config)
      require 'ruby_event_store_rom_sql/rom'

      config.register_relation(ROM::Relations::Events)
      config.register_relation(ROM::Relations::EventStreams)
    end

    def run_migrations_for(gateway)
      gateway.run_migrations(path: File.expand_path('../../db/migrate', File.dirname(__FILE__)))
    end
  end
end
