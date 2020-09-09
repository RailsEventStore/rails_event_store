require 'ruby_event_store/rom'
require_relative '../../support/helpers/rspec_defaults'
require_relative '../../support/helpers/mutant_timeout'
require 'dry/inflector'

ENV['DATABASE_URL'] ||= 'sqlite:db.sqlite3'
