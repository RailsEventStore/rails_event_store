# frozen_string_literal: true

module AggregateRoot
  class InstrumentedApplyStrategy
    def initialize(strategy, instrumentation)
      @strategy = strategy
      @instrumentation = instrumentation
    end

    def call(aggregate, event)
      instrumentation.instrument("apply.aggregate_root", aggregate: aggregate, event: event) do
        strategy.call(aggregate, event)
      end
    end

    def method_missing(method_name, *arguments, &block)
      if respond_to?(method_name)
        strategy.public_send(method_name, *arguments, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private)
      strategy.respond_to?(method_name)
    end

    private

    attr_reader :instrumentation, :strategy
  end
end
