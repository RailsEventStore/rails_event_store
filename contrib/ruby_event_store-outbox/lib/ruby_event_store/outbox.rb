# frozen_string_literal: true

module RubyEventStore
  module Outbox
  end
end

require_relative "outbox/fetch_specification"
require_relative "outbox/repository"
require_relative "outbox/sidekiq_scheduler"
require_relative "outbox/legacy_sidekiq_scheduler"
require_relative "outbox/version"
