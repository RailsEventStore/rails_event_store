require "ruby_event_store"
require "ruby_event_store/spec/scheduler_lint"
require "ruby_event_store/sidekiq_scheduler"
require "rails_event_store"
require_relative "../../../support/helpers/rspec_defaults"
require_relative "../../../support/helpers/time_enrichment"
require_relative "../../../support/helpers/redis_client_unix_socket_patch"
require_relative "../../../support/helpers/silence_stdout"
require_relative "../../../support/helpers/migrator"

SilenceStdout.silence_stdout { require "sidekiq/testing" }
require "sidekiq/processor"

ENV["DATABASE_URL"] ||= "sqlite3::memory:"
ENV["DATA_TYPE"] ||= "binary"

RSpec.configure do |config|
  config.before(:each, redis: true) { Sidekiq.redis(&:itself).flushdb }
end

Sidekiq.configure_client { |config| config.logger.level = Logger::WARN }

module RubyEventStore
  class Queue
    TIMEOUT = 2

    Timeout = Class.new(StandardError)

    def initialize
      @mvar = Concurrent::MVar.new
    end

    def push(event)
      @mvar.put(event)
    end

    def pop(timeout = TIMEOUT)
      res = @mvar.take(timeout)
      raise Timeout if res == Concurrent::MVar::TIMEOUT

      res
    end
  end
end
