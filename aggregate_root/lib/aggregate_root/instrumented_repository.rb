# frozen_string_literal: true

require "delegate"
module AggregateRoot
  class InstrumentedRepository
    def initialize(repository, instrumentation)
      @repository = repository
      @instrumentation = instrumentation
      self.error_handler = method(:handle_error) if respond_to?(:error_handler=)
    end

    def load(aggregate, stream_name)
      instrumentation.instrument("load.repository.aggregate_root", aggregate: aggregate, stream: stream_name) do
        repository.load(aggregate, stream_name)
      end
    end

    def store(aggregate, stream_name)
      instrumentation.instrument(
        "store.repository.aggregate_root",
        aggregate: aggregate,
        version: aggregate.version,
        stored_events: aggregate.unpublished_events.to_a,
        stream: stream_name,
      ) { repository.store(aggregate, stream_name) }
    end

    def with_aggregate(aggregate, stream_name, &block)
      block.call(load(aggregate, stream_name))
      store(aggregate, stream_name)
    end

    def method_missing(method_name, *arguments, **keyword_arguments, &block)
      if respond_to?(method_name)
        repository.public_send(method_name, *arguments, **keyword_arguments, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private)
      repository.respond_to?(method_name)
    end

    private

    def handle_error(error)
      instrumentation.instrument(
        "error_occured.repository.aggregate_root",
        exception: [error.class.name, error.message],
        exception_object: error,
      )
    end

    attr_reader :instrumentation, :repository
  end
end
