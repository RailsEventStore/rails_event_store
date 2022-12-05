require "ruby_event_store"
require "ruby_event_store/sidekiq_scheduler"
require_relative "../../../support/helpers/rspec_defaults"
require_relative "../../../support/helpers/time_enrichment"

RSpec.configure do |config|
  config.before(:each, redis: true) { |example| redis.flushdb }
end

TestEvent = Class.new(RubyEventStore::Event)
