# frozen_string_literal: true

require "active_support/version"
require "active_support/isolated_execution_state" if ActiveSupport.version >= Gem::Version.new("7.0")
require "active_support/notifications"

::RSpec::Matchers.define :match_query_count do |expected_count|
  match do
    count = 0
    ActiveSupport::Notifications.subscribed(
      lambda { |_, _, _, _, payload| count += 1 unless %w[CACHE SCHEMA].include?(payload[:name]) },
      /^sql\./,
      &actual
    )
    values_match?(expected_count, count)
  end
  supports_block_expectations
  diffable
end

::RSpec::Matchers.define :match_query do |expected_query, expected_count = 1|
  match do
    count = 0
    ActiveSupport::Notifications.subscribed(
      lambda { |_, _, _, _, payload| count += 1 if expected_query === payload[:sql] },
      /^sql\./,
      &actual
    )
    values_match?(expected_count, count)
  end
  supports_block_expectations
  diffable
end
