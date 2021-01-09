# frozen_string_literal: true

require 'aggregate_root'
require 'ruby_event_store'
require_relative '../../support/helpers/rspec_defaults'

RSpec.configure do |spec|
  spec.before(:each) do
    AggregateRoot.configure do |config|
      config.default_event_store = nil
    end
  end
end

module Orders
  module Events
    OrderCreated = Class.new(RubyEventStore::Event)
    OrderExpired = Class.new(RubyEventStore::Event)
    OrderCanceled = Class.new(RubyEventStore::Event)
    SpanishInquisition = Class.new(RubyEventStore::Event)
  end
end

class Order
  include AggregateRoot
  include Orders::Events

  def initialize(uuid)
    @status = :draft
    @uuid   = uuid
  end

  def create
    apply OrderCreated.new
  end

  def expire
    apply OrderExpired.new
  end

  attr_accessor :status

  private

  def apply_order_created(_event)
    @status = :created
  end

  def apply_order_expired(_event)
    @status = :expired
  end
end
