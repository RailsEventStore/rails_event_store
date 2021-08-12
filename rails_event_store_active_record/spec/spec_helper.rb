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
