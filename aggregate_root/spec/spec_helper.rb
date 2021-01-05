# frozen_string_literal: true

require "aggregate_root"
require "ruby_event_store"
require_relative "../../support/helpers/rspec_defaults"

module Orders
  module Events
    OrderCreated = Class.new(RubyEventStore::Event)
    OrderExpired = Class.new(RubyEventStore::Event)
    OrderCanceled = Class.new(RubyEventStore::Event)
    SpanishInquisition = Class.new(RubyEventStore::Event)
  end
end