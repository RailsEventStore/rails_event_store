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
  end
end

class Order
  include AggregateRoot::Base

  def initialize(id = generate_uuid)
    self.id = id
    @status = :draft
  end

  private
  attr_accessor :status

  def apply_orders_events_order_created(event)
    @status = :created
  end
end

class CustomOrderApplyStrategy
  def call(aggregate, event)
    {
      Orders::Events::OrderCreated => aggregate.method(:custom_order_processor),
    }.fetch(event.class, ->(ev) {}).call(event)
  end
end

class OrderWithCustomStrategy
  include AggregateRoot::Base

  def initialize(id = generate_uuid)
    self.id = id
    @status = :draft
  end

  def apply_strategy
    @apply_strategy ||= CustomOrderApplyStrategy.new
  end

  private
  attr_accessor :status, :other_value

  def custom_order_processor(event)
    @status = :created
  end
end
