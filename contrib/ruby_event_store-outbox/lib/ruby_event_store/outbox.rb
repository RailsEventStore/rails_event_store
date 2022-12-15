# frozen_string_literal: true

module RubyEventStore
  module Outbox
    Error = Class.new(StandardError)
    RetriableError = Class.new(Error)
  end
end

require_relative "outbox/fetch_specification"
require_relative "outbox/repositories/mysql57"
require_relative "outbox/sidekiq_scheduler"
require_relative "outbox/version"
require_relative "outbox/tempo"
require_relative "outbox/batch_result"
require_relative "outbox/cleanup_strategies"
require_relative "outbox/repositories"
