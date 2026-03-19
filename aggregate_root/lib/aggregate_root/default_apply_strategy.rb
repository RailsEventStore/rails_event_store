# frozen_string_literal: true

module AggregateRoot
  MissingHandler = Class.new(StandardError)

  class DefaultApplyStrategy
    DEPRECATION_MESSAGE = <<~EOW
      Handling events via apply_* method naming convention is deprecated and will be removed in the next major release.

      Use the on DSL instead:

        on %s do |event|
          # your code
        end
    EOW
    private_constant :DEPRECATION_MESSAGE

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
      on_dsl_handler_name(aggregate, event.event_type) || apply_handler_name(aggregate, event.event_type)
    end

    def on_dsl_handler_name(aggregate, event_type)
      aggregate.class.on_methods[event_type] if aggregate.class.respond_to?(:on_methods)
    end

    def apply_handler_name(aggregate, event_type)
      name = "apply_#{Transform.to_snake_case(event_type(event_type))}"
      if aggregate.respond_to?(name, true)
        warn DEPRECATION_MESSAGE % event_type
      end
      name
    end

    def event_type(event_type)
      event_type.split(/::|\./).last
    end

    attr_reader :strict, :on_methods
  end
end
