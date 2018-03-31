require 'ostruct'
require 'thread'

module RubyEventStore
  class InMemoryRepository

    def initialize
      @streams = Hash.new
      @mutex = Mutex.new
      @global = Array.new
    end

    def append_to_stream(events, stream, expected_version)
      add_to_stream(events, expected_version, stream, true)
    end

    def link_to_stream(event_ids, stream, expected_version)
      events = normalize_to_array(event_ids).map {|eid| read_event(eid)}
      add_to_stream(events, expected_version, stream, nil)
    end

    def delete_stream(stream)
      streams.delete(stream.name)
    end

    def has_event?(event_id)
       global.any?{ |item| item.event_id.eql?(event_id) }
    end

    def last_stream_event(stream)
      read_stream_events_forward(stream).last
    end

    def read_events_forward(stream, start_event_id, count)
      Specification.new(self)
        .stream(stream.name)
        .from(start_event_id)
        .limit(count)
        .each
        .to_a
    end

    def read_events_backward(stream, start_event_id, count)
      Specification.new(self)
        .stream(stream.name)
        .from(start_event_id)
        .limit(count)
        .backward
        .each
        .to_a
    end

    def read_stream_events_forward(stream)
      Specification.new(self)
        .stream(stream.name)
        .each
        .to_a
    end

    def read_stream_events_backward(stream)
      Specification.new(self)
        .stream(stream.name)
        .backward
        .each
        .to_a
    end

    def read_all_streams_forward(start_event_id, count)
      Specification.new(self)
        .from(start_event_id)
        .limit(count)
        .each
        .to_a
    end

    def read_all_streams_backward(start_event_id, count)
      Specification.new(self)
        .from(start_event_id)
        .limit(count)
        .backward
        .each
        .to_a
    end

    def read_event(event_id)
      global.find {|e| event_id.eql?(e.event_id)} or raise EventNotFound.new(event_id)
    end

    def read(specification)
      events = specification.stream_name.eql?(GLOBAL_STREAM) ? global : stream_of(specification.stream_name)
      events = events.reverse if specification.direction.equal?(:backward)
      events = read_batch(events, specification.start, specification.count) unless specification.count.equal?(Specification::NO_LIMIT)
      events.each
    end

    private

    def stream_of(name)
      streams.fetch(name, Array.new)
    end

    def normalize_to_array(events)
      return *events
    end

    def add_to_stream(events, expected_version, stream, include_global)
      events = normalize_to_array(events)
      append_with_synchronize(events, expected_version, stream, include_global)
    end

    def last_stream_version(stream)
      read_stream_events_forward(stream).size - 1
    end

    def append_with_synchronize(events, expected_version, stream, include_global)
      resolved_version = expected_version.resolve_for(stream, method(:last_stream_version))

      # expected_version :auto assumes external lock is used
      # which makes reading stream before writing safe.
      #
      # To emulate potential concurrency issues of :auto strategy without
      # such external lock we use Thread.pass to make race
      # conditions more likely. And we only use mutex.synchronize for writing
      # not for the whole read+write algorithm.
      Thread.pass
      mutex.synchronize do
        resolved_version = last_stream_version(stream) if expected_version.any?
        append(events, resolved_version, stream, include_global)
      end
    end

    def append(events, resolved_version, stream, include_global)
      stream_events = stream_of(stream.name)
      raise WrongExpectedEventVersion unless last_stream_version(stream).equal?(resolved_version)
      events.each do |event|
        raise EventDuplicatedInStream if stream_events.any? {|ev| ev.event_id.eql?(event.event_id)}
        if include_global
          raise EventDuplicatedInStream if has_event?(event.event_id)
          global.push(event)
        end
        stream_events.push(event)
      end
      streams[stream.name] = stream_events
      self
    end

    def read_batch(source, start_event_id, count)
      return source[0..count - 1] if start_event_id.equal?(:head)
      start_index = index_of(source, start_event_id)
      source[start_index + 1..start_index + count]
    end

    def index_of(source, event_id)
      source.index {|item| item.event_id.eql?(event_id)}
    end

    attr_reader :streams, :mutex, :global
  end
end
