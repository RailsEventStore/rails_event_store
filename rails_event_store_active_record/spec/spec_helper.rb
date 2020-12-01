require 'rails_event_store_active_record'
require_relative '../../support/helpers/rspec_defaults'
require_relative '../../support/helpers/migrator'
require_relative '../../support/helpers/schema_helper'
require 'rails'
require 'active_record'


$verbose = ENV.has_key?('VERBOSE') ? true : false
ActiveRecord::Schema.verbose = $verbose

ENV['DATABASE_URL']  ||= 'sqlite3:db.sqlite3'

module RailsEventStoreActiveRecord
  class CustomApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end

RSpec::Matchers.define :contains_ids do |expected_ids|
  match do |enum|
    @actual = enum.map(&:event_id)
    values_match?(expected_ids, @actual)
  end
  diffable
end
