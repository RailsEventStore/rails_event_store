module AggregateRoot
  class InstrumentedRepository
    def initialize(repository, instrumentation)
      @repository = repository
      @instrumentation = instrumentation
    end

    def load(aggregate, stream_name)
      instrumentation.instrument("load.repository.aggregate_root",
                                 aggregate_class: aggregate.class,
                                 stream_name: stream_name) do
        repository.load(aggregate, stream_name)
      end
    end

    def store(aggregate, stream_name)
      instrumentation.instrument("store.repository.aggregate_root",
                                 aggregate_class: aggregate.class,
                                 aggregate_version: aggregate.version,
                                 stored_events: aggregate.unpublished_events.size,
                                 stream_name: stream_name) do
        repository.store(aggregate, stream_name)
      end
    end

    def with_aggregate(aggregate, stream_name, &block)
      repository.with_aggregate(aggregate, stream_name, &block)
    end

    private
    attr_reader :instrumentation, :repository
  end
end
