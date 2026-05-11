# frozen_string_literal: true

module AggregateRoot
  class Repository
    def initialize(event_store = default_event_store)
      @event_store = event_store
    end

    def load(aggregate, stream_name)
      event_store.read.stream(stream_name).reduce { |_, ev| aggregate.apply(ev) }
      event_count = aggregate.unpublished_events.size # mutant:disable
      aggregate.version = event_count - 1
      aggregate
    end

    def store(aggregate, stream_name)
      event_store.publish(
        aggregate.unpublished_events.to_a,
        stream_name: stream_name,
        expected_version: aggregate.version,
      )
      event_count = aggregate.unpublished_events.size # mutant:disable
      aggregate.version = aggregate.version + event_count
    end

    def with_aggregate(aggregate, stream_name, &block)
      block.call(load(aggregate, stream_name))
      store(aggregate, stream_name)
    end

    private

    attr_reader :event_store

    def default_event_store
      warn <<~EOW
        DEPRECATION WARNING: Calling `AggregateRoot::Repository.new` without an event store argument relies on `AggregateRoot::Configuration` which is deprecated and will be removed in the next major release.
        Use `AggregateRoot::Repository.new(event_store)` with explicit event store injection instead.
      EOW
      AggregateRoot.configuration.default_event_store
    end
  end
end
