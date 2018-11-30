require 'rails_event_store_active_record'
require_relative '../../lib/rspec_defaults'
require_relative '../../lib/mutant_timeout'
require_relative '../../lib/migrator'
require_relative '../../lib/schema_helper'
require 'rails'


$verbose = ENV.has_key?('VERBOSE') ? true : false
ActiveRecord::Schema.verbose = $verbose

ENV['DATABASE_URL']  ||= 'sqlite3:db.sqlite3'

RSpec::Matchers.define :contains_ids do |expected_ids|
  match do |enum|
    @actual = enum.map(&:event_id)
    values_match?(expected_ids, @actual)
  end
  diffable
end