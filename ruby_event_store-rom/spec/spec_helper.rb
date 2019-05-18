require 'ruby_event_store/rom'
require_relative '../../support/helpers/rspec_defaults'
require_relative '../../support/helpers/mutant_timeout'
require 'dry/inflector'

begin
  require 'pry'
  require 'pry-byebug'
rescue LoadError
end

ENV['DATABASE_URL'] ||= 'sqlite:db.sqlite3'

module RomHelpers
  def env
    rom_helper.env
  end

  def rom_container
    env.rom_container
  end

  def rom_db
    rom_container.gateways[:default]
  end
end
