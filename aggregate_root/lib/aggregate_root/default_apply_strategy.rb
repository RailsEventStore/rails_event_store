module AggregateRoot
  MissingHandler = Class.new(StandardError)

  class DefaultApplyStrategy
    def initialize(strict: true, on_methods: {})
      @strict = strict
      @on_methods = on_methods
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

    def handler_name(event)
      on_methods.fetch(event.class) { handler_name_by_class(event.class) }
    end

    def handler_name_by_class(event_class)
      "apply_#{to_snake_case(event_class.name)}"
    end

    def to_snake_case(class_name)
      class_name
        .split("::")
        .last
        .gsub(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
    end

    private
    attr_reader :strict, :on_methods
  end
end
