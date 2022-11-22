require "ruby_event_store"
require "ruby_event_store/outbox"
require "ruby_event_store/outbox/cli"
require "ruby_event_store/outbox/metrics/null"
require "ruby_event_store/outbox/metrics/influx"
require "ruby_event_store/outbox/metrics/test"
require_relative "../../../support/helpers/rspec_defaults"
require_relative "../../../support/helpers/schema_helper"
require_relative "../../../support/helpers/time_enrichment"
require_relative "./support/db"
require "rails"
require "active_support/testing/time_helpers.rb"

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
  config.after(:each) { travel_back }
  config.before(:each, redis: true) { |example| redis.flushdb }
end

$verbose = ENV.has_key?("VERBOSE") ? true : false
ActiveRecord::Schema.verbose = $verbose

ENV["DATABASE_URL"] ||= "sqlite3::memory:"

module RedisIsolation
  def self.redis_url
    ENV["REDIS_URL"]
  end
end

class TickingClock
  def initialize(start: Time.now.utc, tick_by: 1)
    @start = start.change(usec: 0)
    @next = @start.dup
    @tick_by = tick_by
  end

  def now
    current = @next.dup
    @next += tick_by
    current
  end

  def test_travel(ticks)
    @next += ticks
  end

  def tick(index)
    start.dup + index * tick_by
  end

  attr_reader :start, :tick_by
end
