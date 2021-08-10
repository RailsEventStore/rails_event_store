require "rails_event_store_active_record"
require_relative "../../support/helpers/rspec_defaults"
require_relative "../../support/helpers/migrator"
require_relative "../../support/helpers/schema_helper"
require "rails"
require "active_record"


$verbose = ENV.has_key?("VERBOSE") ? true : false
ActiveRecord::Schema.verbose = $verbose

ENV["DATABASE_URL"]  ||= "sqlite3:db.sqlite3"

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

RSpec::Matchers.define :match_query_count_of do |expected_count|
  match do |query|
    count = 0
    ActiveSupport::Notifications.subscribed(
      lambda do |_name, _started, _finished, _unique_id, payload|
        unless %w[ CACHE SCHEMA ].include?(payload[:name])
          count += 1
        end
      end,
      "sql.active_record",
      &actual
    )
    values_match?(expected_count, count)
  end
  supports_block_expectations
  diffable
end
