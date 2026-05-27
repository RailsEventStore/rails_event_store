# frozen_string_literal: true

module AggregateRoot
  MissingHandler = Class.new(StandardError)

  class DefaultApplyStrategy
    def initialize(strict: true)
      @strict = strict
    end

    def call(aggregate, event)
      name = handler_name(aggregate, event)
      if name
        aggregate.method(name).call(event)
      elsif strict
        raise MissingHandler.new("Missing handler method for #{event.event_type} on aggregate #{aggregate.class}")
      end
    end

    private

    def handler_name(aggregate, event)
      on_dsl_handler_name(aggregate, event.event_type)
    end

    def on_dsl_handler_name(aggregate, event_type)
      aggregate.class.on_methods[event_type] if aggregate.class.respond_to?(:on_methods)
    end

    attr_reader :strict
  end
end
