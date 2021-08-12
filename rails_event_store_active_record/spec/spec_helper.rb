require "rails_event_store_active_record"
require_relative "../../support/helpers/rspec_defaults"
require_relative "../../support/helpers/migrator"
require_relative "../../support/helpers/schema_helper"
require "rails"
require "active_record"

$verbose = ENV.has_key?("VERBOSE") ? true : false
ActiveRecord::Schema.verbose = $verbose

module RailsEventStoreActiveRecord
  class CustomApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end

  class SpecHelper
    include SchemaHelper

    def run_lifecycle
      establish_database_connection
      load_database_schema
      yield
    ensure
      drop_database
    end

    def with_transaction
      ActiveRecord::Base.transaction do
        yield
      end
    end

    def supports_concurrent_auto?
      !ENV["DATABASE_URL"].include?("sqlite")
    end

    def supports_concurrent_any?
      !ENV["DATABASE_URL"].include?("sqlite")
    end

    def supports_binary?
      true
    end

    def supports_upsert?
      true
    end

    def has_connection_pooling?
      true
    end

    def connection_pool_size
      ActiveRecord::Base.connection.pool.size
    end

    def cleanup_concurrency_test
      ActiveRecord::Base.connection_pool.disconnect!
    end

    def supports_position_queries?
      true
    end
  end
end

RSpec::Matchers.define :match_query_count_of do |expected_count|
  match do
    count = 0
    ActiveSupport::Notifications.subscribed(
      lambda { |_, _, _, _, payload| count += 1 unless %w[CACHE SCHEMA].include?(payload[:name]) },
      "sql.active_record",
      &actual
    )
    values_match?(expected_count, count)
  end
  supports_block_expectations
  diffable
end

RSpec::Matchers.define :match_query do |expected_query, expected_count = 1|
  match do
    count = 0
    ActiveSupport::Notifications.subscribed(
      lambda { |_, _, _, _, payload| count += 1 if expected_query === payload[:sql] },
      "sql.active_record",
      &actual
    )
    values_match?(expected_count, count)
  end
  supports_block_expectations
  diffable
end