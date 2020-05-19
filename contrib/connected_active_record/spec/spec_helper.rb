require '../../support/helpers/rspec_defaults'
require_relative '../../../support/helpers/schema_helper'
require 'connected_active_record'

$verbose = ENV.has_key?('VERBOSE') ? true : false
ActiveRecord::Schema.verbose = $verbose

ENV['DATABASE_URL']  ||= 'sqlite3:db.sqlite3'