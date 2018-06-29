require 'ruby_event_store/rom'
require 'support/rspec_defaults'
require 'support/mutant_timeout'
require 'dry/inflector'

begin
  require 'pry'
  require 'pry-byebug'
rescue LoadError
end

RSpec.configure do |config|
  config.failure_color = :magenta
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
