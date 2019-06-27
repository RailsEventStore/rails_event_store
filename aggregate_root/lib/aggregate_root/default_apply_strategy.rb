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
      aggregate.class.on_methods.fetch(event.type) { handler_name_by_type(event.type) }
    end

    def handler_name_by_type(event_type)
      "apply_#{Transform.to_snake_case(event_type(event_type))}"
    end

    def event_type(event_type)
      event_type.split(%r{::|\.}).last
    end

    attr_reader :strict, :on_methods
  end
end
