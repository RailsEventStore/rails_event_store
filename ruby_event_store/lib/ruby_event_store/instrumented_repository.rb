# frozen_string_literal: true

module RubyEventStore
  class InstrumentedRepository
    def initialize(repository, instrumentation)
      @repository = repository
      @instrumentation = instrumentation
    end

    def append_to_stream(records, stream, expected_version)
      instrumentation.instrument("append_to_stream.repository.ruby_event_store", records: records, stream: stream) do
        repository.append_to_stream(records, stream, expected_version)
      end
    end

    def link_to_stream(event_ids, stream, expected_version)
      instrumentation.instrument("link_to_stream.repository.ruby_event_store", event_ids: event_ids, stream: stream) do
        repository.link_to_stream(event_ids, stream, expected_version)
      end
    end

    def delete_stream(stream)
      instrumentation.instrument("delete_stream.repository.ruby_event_store", stream: stream) do
        repository.delete_stream(stream)
      end
    end

    def read(specification)
      instrumentation.instrument("read.repository.ruby_event_store", specification: specification) do
        repository.read(specification)
      end
    end

    def count(specification)
      instrumentation.instrument("count.repository.ruby_event_store", specification: specification) do
        repository.count(specification)
      end
    end

    def update_messages(records)
      instrumentation.instrument("update_messages.repository.ruby_event_store", records: records) do
        repository.update_messages(records)
      end
    end

    def streams_of(event_id)
      instrumentation.instrument("streams_of.repository.ruby_event_store", event_id: event_id) do
        repository.streams_of(event_id)
      end
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

    attr_reader :repository, :instrumentation
  end
end
