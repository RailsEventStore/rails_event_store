require 'ostruct'
require 'thread'

module RubyEventStore
  class InMemoryRepository

    def initialize
      @streams = Hash.new
      @mutex = Mutex.new
      @streams[GLOBAL_STREAM] = Array.new
    end

    def append_to_stream(events, stream, expected_version)
      add_to_stream(events, expected_version, stream, true)
    end

    def link_to_stream(event_ids, stream, expected_version)
      events = normalize_to_array(event_ids).map{|eid| read_event(eid) }
      add_to_stream(events, expected_version, stream, nil)
    end

    def delete_stream(stream)
      streams.delete(stream.name)
    end

    def has_event?(event_id)
      streams.fetch(GLOBAL_STREAM).any? { |item| item.event_id.eql?(event_id) }
    end

    def last_stream_event(stream)
      read_stream_events_forward(stream).last
    end

    def read_events_forward(stream, start_event_id, count)
      source = read_stream_events_forward(stream)
      read_batch(source, start_event_id, count)
    end

    def read_events_backward(stream, start_event_id, count)
      source = read_stream_events_backward(stream)
      read_batch(source, start_event_id, count)
    end

    def read_stream_events_forward(stream)
      streams.fetch(stream.name, Array.new)
    end

    def read_stream_events_backward(stream)
      read_stream_events_forward(stream).reverse
    end

    def read_all_streams_forward(start_event_id, count)
      read_events_forward(Stream.new(GLOBAL_STREAM), start_event_id, count)
    end

    def read_all_streams_backward(start_event_id, count)
      read_events_backward(Stream.new(GLOBAL_STREAM), start_event_id, count)
    end

    def read_event(event_id)
      streams.fetch(GLOBAL_STREAM).find { |e| event_id.eql?(e.event_id) } or raise EventNotFound.new(event_id)
    end

    private

    def normalize_to_array(events)
      return *events
    end

    def add_to_stream(events, expected_version, stream, include_global)
      raise InvalidExpectedVersion if !expected_version.equal?(:any) && stream.global?
      events = normalize_to_array(events)
      expected_version = case expected_version
        when :none
          -1
        when :auto
          read_stream_events_forward(stream).size - 1
        when Integer, :any
          expected_version
        else
         raise InvalidExpectedVersion
      end
      append_with_synchronize(events, expected_version, stream, include_global)
    end

    def append_with_synchronize(events, expected_version, stream, include_global)
      # expected_version :auto assumes external lock is used
      # which makes reading stream before writing safe.
      #
      # To emulate potential concurrency issues of :auto strategy without
      # such external lock we use Thread.pass to make race
      # conditions more likely. And we only use mutex.synchronize for writing
      # not for the whole read+write algorithm.
      Thread.pass
      mutex.synchronize do
        if expected_version == :any
          expected_version = read_stream_events_forward(stream).size - 1
        end
        append(events, expected_version, stream, include_global)
      end
    end

    def append(events, expected_version, stream, include_global)
      stream_ = read_stream_events_forward(stream)
      raise WrongExpectedEventVersion unless (stream_.size - 1).equal?(expected_version)
      events.each do |event|
        raise EventDuplicatedInStream if stream_.any?{|ev| ev.event_id.eql?(event.event_id) }
        if include_global
          global_stream = read_stream_events_forward(Stream.new(GLOBAL_STREAM))
          raise EventDuplicatedInStream if global_stream.any? { |ev| ev.event_id.eql?(event.event_id) }
          global_stream.push(event)
        end
        stream_.push(event) unless stream.global?
      end
      streams[stream.name] = stream_
      self
    end

    def read_batch(source, start_event_id, count)
      return source[0..count-1] if start_event_id.equal?(:head)
      start_index = index_of(source, start_event_id)
      source[start_index+1..start_index+count]
    end

    def index_of(source, event_id)
      source.index{ |item| item.event_id.eql?(event_id) }
    end

    attr_reader :streams, :mutex
  end
end
