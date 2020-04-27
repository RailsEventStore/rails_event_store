# frozen_string_literal: true

module AggregateRoot
  MissingHandler = Class.new(StandardError)

  class DefaultApplyStrategy
    def initialize(strict: true)
      @strict = strict
    end

    def call(aggregate, event)
      name = handler_name(aggregate, event)
      if aggregate.respond_to?(name, true)
        aggregate.method(name).call(event)
      else
        raise MissingHandler.new("Missing handler method #{name} on aggregate #{aggregate.class}") if strict
      end
    end

    private

    def handler_name(aggregate, event)
      on_dsl_handler_name(aggregate, event.event_type) || apply_handler_name(event.event_type)
    end

    def on_dsl_handler_name(aggregate, event_type)
      aggregate.class.on_methods[event_type] if aggregate.class.respond_to?(:on_methods)
    end

    def apply_handler_name(event_type)
      "apply_#{Transform.to_snake_case(event_type(event_type))}"
    end

    def event_type(event_type)
      event_type.split(%r{::|\.}).last
    end

    attr_reader :strict, :on_methods
  end
end
