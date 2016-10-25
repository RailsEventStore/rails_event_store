if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

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
  end
end

class Order
  include AggregateRoot

  def initialize
    @status = :draft
  end

  attr_accessor :status
  private

  def apply_orders_events_order_created(event)
    @status = :created
  end

  def apply_orders_events_order_expired(event)
    @status = :expired
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
