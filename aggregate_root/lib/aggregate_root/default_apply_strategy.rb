module AggregateRoot
  MissingHandler = Class.new(StandardError)

  class DefaultApplyStrategy
    def initialize(strict: true)
      @strict = strict
    end

    def call(aggregate, event)
      name = handler_name(event)
      if aggregate.respond_to?(name, true)
        aggregate.method(name).call(event)
      else
        raise MissingHandler.new("Missing handler method #{name} on aggregate #{aggregate.class}") if strict
      end
    end

    private
    attr_reader :strict

    def handler_name(event)
      "apply_#{event.class.name.demodulize.underscore}"
    end
  end
end
