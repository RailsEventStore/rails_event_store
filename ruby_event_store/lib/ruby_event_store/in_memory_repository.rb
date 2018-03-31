require 'ostruct'
require 'thread'

module RubyEventStore
  class InMemoryRepository

    def initialize
      @all = Array.new
      @streams = Hash.new
      @mutex = Mutex.new
    end

    def append_to_stream(events, stream_name, expected_version)
      add_to_stream(events, expected_version, stream_name, true)
    end

    def link_to_stream(event_ids, stream_name, expected_version)
      events = normalize_to_array(event_ids).map{|eid| read_event(eid) }
      add_to_stream(events, expected_version, stream_name, nil)
    end

    def delete_stream(stream_name)
      @streams.delete(stream_name)
    end

    def has_event?(event_id)
      @all.any?{ |item| item.event_id.eql?(event_id) }
    end

    def last_stream_event(stream_name)
      read_stream_events_forward(stream_name).last
    end

    def read_events_forward(stream_name, start_event_id, count)
      source = read_stream_events_forward(stream_name)
      read_batch(source, start_event_id, count)
    end

    def read_events_backward(stream_name, start_event_id, count)
      source = read_stream_events_backward(stream_name)
      read_batch(source, start_event_id, count)
    end

    def read_stream_events_forward(stream_name)
      return @all if stream_name.eql?(GLOBAL_STREAM)
      @streams[stream_name] || Array.new
    end

    def read_stream_events_backward(stream_name)
      return @all if stream_name.eql?(GLOBAL_STREAM)
      read_stream_events_forward(stream_name).reverse
    end

    def read_all_streams_forward(start_event_id, count)
      read_batch(@all, start_event_id, count)
    end

    def read_all_streams_backward(start_event_id, count)
      read_batch(@all.reverse, start_event_id, count)
    end

    def read_event(event_id)
      @all.find { |e| event_id.eql?(e.event_id) } or raise EventNotFound.new(event_id)
    end

    def get_all_streams
      [Stream.new("all")] + @streams.keys.map { |name| Stream.new(name) }
    end

    private

    def normalize_to_array(events)
      return *events
    end

    def add_to_stream(events, expected_version, stream_name, include_global)
      raise InvalidExpectedVersion if !expected_version.equal?(:any) && stream_name.eql?(GLOBAL_STREAM)
      events = normalize_to_array(events)
      expected_version = case expected_version
        when :none
          -1
        when :auto
          read_stream_events_forward(stream_name).size - 1
        when Integer, :any
          expected_version
        else
         raise InvalidExpectedVersion
      end
      append_with_synchronize(events, expected_version, stream_name, include_global)
    end

    def append_with_synchronize(events, expected_version, stream_name, include_global)
      # expected_version :auto assumes external lock is used
      # which makes reading stream before writing safe.
      #
      # To emulate potential concurrency issues of :auto strategy without
      # such external lock we use Thread.pass to make race
      # conditions more likely. And we only use mutex.synchronize for writing
      # not for the whole read+write algorithm.
      Thread.pass
      @mutex.synchronize do
        if expected_version == :any
          expected_version = read_stream_events_forward(stream_name).size - 1
        end
        append(events, expected_version, stream_name, include_global)
      end
    end

    def append(events, expected_version, stream_name, include_global)
      stream = read_stream_events_forward(stream_name)
      raise WrongExpectedEventVersion unless (stream.size - 1).equal?(expected_version)
      events.each do |event|
        raise EventDuplicatedInStream if stream.any?{|ev| ev.event_id.eql?(event.event_id) }
        if include_global
          raise EventDuplicatedInStream if @all.any?{|ev| ev.event_id.eql?(event.event_id) }
          @all.push(event)
        end
        stream.push(event) unless stream_name.eql?(GLOBAL_STREAM)
      end
      @streams[stream_name] = stream
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
  end
end
