require "ruby_event_store"
require "ruby_event_store/sidekiq_scheduler"
require_relative "../../../support/helpers/rspec_defaults"
require_relative "../../../support/helpers/time_enrichment"

ENV["DATABASE_URL"] ||= "sqlite3::memory:"
ENV["DATA_TYPE"] ||= "binary"

RSpec.configure do |config|
  config.before(:each, redis: true) { |example| redis.flushdb }
end

TestEvent = Class.new(RubyEventStore::Event)

class RedisClient
  class Config
    prepend(
      Module.new do
        def initialize(url: nil, **kwargs)
          uri = URI.parse(url)
          if uri.scheme == "unix"
            super(**kwargs, url: nil)
            @path = uri.path
          else
            super
          end
        end
      end
    )
  end
end