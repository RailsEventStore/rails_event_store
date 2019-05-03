require 'aggregate_root/version'
require 'aggregate_root/configuration'
require 'aggregate_root/transform'
require 'aggregate_root/default_apply_strategy'
require 'aggregate_root/repository'

module AggregateRoot
  module ClassMethods
    def on(*event_klasses, &block)
      event_klasses.each do |event_klass|
        name = event_klass.name || raise(ArgumentError, "Anonymous class is missing name")
        handler_name = "on_#{name}"
        define_method(handler_name, &block)
        @on_methods ||= {}
        @on_methods[name]=handler_name
        private(handler_name)
      end
    end

    def on_methods
      ancestors.
        select{|k| k.instance_variables.include?(:@on_methods)}.
        map{|k| k.instance_variable_get(:@on_methods) }.
        inject({}, &:merge)
    end
  end

  def self.included(host_class)
    host_class.extend(ClassMethods)
  end

  def apply(*events)
    events.each do |event|
      apply_strategy.(self, event)
      unpublished << event
    end
  end

  def version
    @version ||= -1
  end

  def version=(value)
    @unpublished_events = nil
    @version = value
  end

  def unpublished_events
    unpublished.each
  end

  def load(stream_name, event_store: default_event_store)
    warn <<~EOW
      Method `load` on aggregate is deprecated. Use AggregateRoot::Repository instead.
      Instead of: `order = Order.new.load("OrderStreamHere")`
      you need to have code:
      ```
      repository = AggregateRoot::Repository.new
      order = repository.load(Order.new, "OrderStreamHere")
      ```
    EOW
    @loaded_from_stream_name = stream_name
    Repository.new(event_store).load(self, stream_name)
  end

  def store(stream_name = loaded_from_stream_name, event_store: default_event_store)
    warn <<~EOW
      Method `store` on aggregate is deprecated. Use AggregateRoot::Repository instead.
      Instead of: `order.store("OrderStreamHere")`
      you need to have code:
      ```
      repository = AggregateRoot::Repository.new
      # load and order and execute some operation on it here
      repository.store(order, "OrderStreamHere")
      ```
    EOW
    Repository.new(event_store).store(self, stream_name)
  end

  private
  attr_reader :loaded_from_stream_name

  def default_event_store
    AggregateRoot.configuration.default_event_store
  end

  def unpublished
    @unpublished_events ||= []
  end

  def apply_strategy
    DefaultApplyStrategy.new(on_methods: self.class.on_methods)
  end
end
