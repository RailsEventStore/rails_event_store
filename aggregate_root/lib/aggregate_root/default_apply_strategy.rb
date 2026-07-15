# frozen_string_literal: true

module AggregateRoot
  MissingHandler = Class.new(StandardError)
  NullHandler    = Proc.new {}

  class DefaultApplyStrategy
    def initialize(strict: true, event_type_resolver: ->(value) { value.to_s })
      @strict = strict
      @event_type_resolver = event_type_resolver
    end

    def call(aggregate, event)
      on_handler(aggregate, event_type_resolver.call(event.class))[event]
    end

    def uses_on_dsl? = true

    private

    def on_handler(aggregate, event_type)
      on_method_name = aggregate.class.on_methods.fetch(event_type)
      aggregate.method(on_method_name)
    rescue KeyError, NoMethodError
      missing_handler(aggregate, event_type)
    end

    def missing_handler(aggregate, event_type)
      if strict
        lambda { |event| raise MissingHandler.new("Missing handler method on aggregate #{aggregate.class} for #{event_type}") }
      else
        NullHandler
      end
    end

    attr_reader :strict, :on_methods, :event_type_resolver
  end
end
