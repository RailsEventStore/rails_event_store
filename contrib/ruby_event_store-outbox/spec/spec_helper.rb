require 'ruby_event_store'
require "ruby_event_store/outbox"
require "ruby_event_store/outbox/cli"
require "ruby_event_store/outbox/metrics/null"
require "ruby_event_store/outbox/metrics/influx"
require "ruby_event_store/outbox/metrics/test"
require_relative '../../../support/helpers/rspec_defaults'
require_relative '../../../support/helpers/schema_helper'
require_relative '../../../support/helpers/time_enrichment'
require_relative './support/db'
require 'rails'
require 'active_support/testing/time_helpers.rb'

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
  config.after(:each) { travel_back }
  config.before(:each, redis: true) do |example|
    redis.flushdb
  end
end

$verbose = ENV.has_key?('VERBOSE') ? true : false
ActiveRecord::Schema.verbose = $verbose

ENV['DATABASE_URL'] ||= 'sqlite3::memory:'


class MutantIdGenerator
  def initialize(redis_url, value_for_main_pid, name)
    @main_pid = Process.pid
    @redis = Redis.new(url: redis_url)
    @value_for_main_pid = value_for_main_pid
    @redis_key = "mutant-something-#{name}"
    @redis.del(@redis_key)
  end

  def id_for_current_pid
    pid = Process.pid
    if pid == @main_pid
      @value_for_main_pid
    else
      get_id_for_pid(pid) || set_id_for_pid(pid)
    end
  end

  private

  def get_id_for_pid(pid)
    position = @redis.lpos(@redis_key, pid)
    position.nil? ? nil : position + 1
  end

  def set_id_for_pid(pid)
    length_of_list_after_push = @redis.rpush(@redis_key, pid)
    length_of_list_after_push
  end
end

RedisMutantIdGenerator = MutantIdGenerator.new("redis://localhost:6379/0", 0, "redis")

module RedisIsolation
  def self.redis_url
    ENV["REDIS_URL"] || per_process_redis_url_for_mutant_runs
  end

  private

  def self.per_process_redis_url_for_mutant_runs
    "redis://localhost:6379/#{RedisMutantIdGenerator.id_for_current_pid}"
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
