require 'aggregate_root/version'
require 'aggregate_root/configuration'
require 'aggregate_root/transform'
require 'aggregate_root/default_apply_strategy'
require 'aggregate_root/repository'


module AggregateRoot
  module OnDSL
    def on(*event_klasses, &block)
      event_klasses.each do |event_klass|
        name = event_klass.to_s
        raise(ArgumentError, "Anonymous class is missing name") if name.start_with? "#<Class:"
        handler_name = "on_#{name}"
        define_method(handler_name, &block)
        @on_methods ||= {}
        on_methods[name] = handler_name
        private(handler_name)
      end
    end

    def on_methods
      @on_methods || {}
    end
  end

  module AggregateMethods
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

    private

    def unpublished
      @unpublished_events ||= []
    end
  end

  def self.with_default_apply_strategy
    Module.new do
      def self.included(host_class)
        host_class.extend  OnDSL
        host_class.include AggregateRoot.with_strategy(->{ DefaultApplyStrategy.new(on_methods: host_class.on_methods) })
      end
    end
  end

  def self.with_strategy(strategy)
    Module.new do
      def self.included(host_class)
        host_class.include AggregateMethods
      end

      define_method :apply_strategy do
        strategy.call
      end
    end
  end

  def self.included(host_class)
    host_class.include with_default_apply_strategy
  end
end
