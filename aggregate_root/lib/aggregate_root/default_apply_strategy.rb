# frozen_string_literal: true

require "ruby_event_store/deprecations"

module AggregateRoot
  MissingHandler = Class.new(StandardError)
  NullHandler    = Proc.new {}

  EVENT_TYPE_RESOLVER_DEPRECATION = <<~EOW.freeze
    Passing event_type_resolver to AggregateRoot has been deprecated.

    Event type is now derived from event.event_type. The event_type_resolver
    argument is ignored and will be removed in a future release.
  EOW

  class DefaultApplyStrategy
    def initialize(strict: true, event_type_resolver: nil)
      @strict = strict
      unless event_type_resolver.nil?
        RubyEventStore::Deprecations.warn(:aggregate_root_event_type_resolver, message: EVENT_TYPE_RESOLVER_DEPRECATION)
      end
    end

    def call(aggregate, event)
      on_handler(aggregate, event.event_type)[event]
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

    attr_reader :strict, :on_methods
  end
end
