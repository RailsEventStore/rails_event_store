# frozen_string_literal: true

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

ENV["DATABASE_URL"] ||= "sqlite3::memory:"

module RecordHelper
  def pick_up_the_pace(consumer, batch_size)
    (Math.log2(batch_size).round + 1).times { consumer.process }
  end

  def create_record(queue, split_key, format: "sidekiq5")
    payload = {
      class: "SomeAsyncHandler",
      queue: queue,
      created_at: Time.now.utc,
      jid: SecureRandom.hex(12),
      retry: true,
      args: [
        {
          event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
          event_type: "RubyEventStore::Event",
          data: "--- {}\n",
          metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
        },
      ],
    }
    RubyEventStore::Outbox::Repository::Record.create!(
      split_key: split_key,
      created_at: Time.now.utc,
      format: format,
      enqueued_at: nil,
      payload: payload.to_json,
    )
  end
end

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
  config.include RecordHelper
  config.after { travel_back }
  config.before(:each, :redis) { |_| redis.call("FLUSHDB") }
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
