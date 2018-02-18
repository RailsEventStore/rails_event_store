$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'aggregate_root'
require 'ruby_event_store'

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
    SpanishInquisition = Class.new(RubyEventStore::Event)
  end
end

class Order
  include AggregateRoot
  include Orders::Events

  def initialize
    @status = :draft
  end

  attr_accessor :status
  private

  on OrderCreated do |_event|
    @status = :created
  end

  def apply_order_expired(_event)
    @status = :expired
  end
end

class OrderWithNonStrictApplyStrategy
  include AggregateRoot
  def apply_strategy
    DefaultApplyStrategy.new(strict: false)
  end
end

class CustomOrderApplyStrategy
  def call(aggregate, event)
    {
      Orders::Events::OrderCreated => aggregate.method(:custom_created),
      Orders::Events::OrderExpired => aggregate.method(:custom_expired),
    }.fetch(event.class, ->(ev) {}).call(event)
  end
end

class OrderWithCustomStrategy
  include AggregateRoot

  def initialize
    @status = :draft
  end

  def apply_strategy
    @apply_strategy ||= CustomOrderApplyStrategy.new
  end

  attr_accessor :status
  private

  def custom_created(event)
    @status = :created
  end

  def custom_expired(event)
    @status = :expired
  end
end

class OrderWithOns
  include AggregateRoot
  include Orders::Events

  on OrderCreated do |_ev|
    @status = :created
  end

  on OrderExpired do |_ev|
    @status = :expired
  end

  attr_accessor :status
end

class InheritedOrderWithOns < OrderWithOns
  include AggregateRoot
  include Orders::Events

  on OrderCreated do |_ev|
    @status = :created_inherited
  end
end