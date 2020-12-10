require 'ruby_event_store'
require "ruby_event_store/outbox"
require "ruby_event_store/outbox/cli"
require "ruby_event_store/outbox/metrics/null"
require "ruby_event_store/outbox/metrics/influx"
require_relative '../../../support/helpers/rspec_defaults'
require_relative '../../../support/helpers/schema_helper'
require_relative './support/db'
require 'rails'

module TimeEnrichment
  def with(event, timestamp: Time.now.utc, valid_at: nil)
    event.metadata[:timestamp] ||= timestamp
    event.metadata[:valid_at] ||= valid_at || timestamp
    event
  end
  module_function :with
end

$verbose = ENV.has_key?('VERBOSE') ? true : false
ActiveRecord::Schema.verbose = $verbose

ENV['DATABASE_URL'] ||= 'sqlite3::memory:'

module RedisIsolation
  def self.redis_url
    ENV["REDIS_URL"] || per_process_redis_url_for_mutant_runs
  end

  private

  def self.per_process_redis_url_for_mutant_runs
    "redis://localhost:6379/#{Process.pid}"
  end
end


class TickingClock
  def initialize(start: Time.now.utc, tick_by: 1)
    @start = start.change(usec: start.usec)
    @next = @start.dup
    @tick_by = tick_by
  end

  def now
    current = @next.dup
    @next += tick_by
    current
  end

  def tick(index)
    start.dup + index * tick_by
  end

  attr_reader :start, :tick_by
end
