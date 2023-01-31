require "ruby_event_store"
require "ruby_event_store/sidekiq_scheduler"
require_relative "../../../support/helpers/rspec_defaults"
require_relative "../../../support/helpers/time_enrichment"
require_relative "../../../support/helpers/redis_client_unix_socket_patch"

ENV["DATABASE_URL"] ||= "sqlite3::memory:"
ENV["DATA_TYPE"] ||= "binary"

RSpec.configure do |config|
  config.before(:each, redis: true) { |example| redis.flushdb }
end

TestEvent = Class.new(RubyEventStore::Event)

