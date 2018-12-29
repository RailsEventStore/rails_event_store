require 'ruby_event_store/rom'
require_relative '../../lib/rspec_defaults'
require_relative '../../lib/mutant_timeout'
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

  def container
    env.container
  end

  def rom_db
    container.gateways[:default]
  end
end
