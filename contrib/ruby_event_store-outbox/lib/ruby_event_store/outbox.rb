# frozen_string_literal: true

module RubyEventStore
  module Outbox
  end
end

require_relative 'outbox/fetch_specification'
require_relative 'outbox/record'
require_relative 'outbox/sidekiq_scheduler'
require_relative 'outbox/consumer'
require_relative 'outbox/version'
