require 'ostruct'
require 'thread'

module RubyEventStore
  class InMemoryRepository
    include Repository

    def initialize(mapper: Mappers::Default.new)
      @all = Array.new
      @streams = Hash.new
      @mutex = Mutex.new
      @mapper = mapper
    end

    def link_to_stream(event_ids, stream_name, expected_version)
      events = normalize_to_array(event_ids).map(&method(:read_event))
      add_to_stream(events, stream_name, expected_version, nil)
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
      @streams[stream_name] || Array.new
    end

    def read_stream_events_backward(stream_name)
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

    def add_metadata(event, key, value)
      @mapper.add_metadata(event, key, value)
    end

    private

    def append(events, stream_name, expected_version, include_global)
      # expected_version :auto assumes external lock is used
      # which makes reading stream before writing safe.
      #
      # To emulate potential concurrency issues of :auto strategy without
      # such external lock we use Thread.pass to make race
      # conditions more likely. And we only use mutex.synchronize for writing
      # not for the whole read+write algorithm.
      Thread.pass
      @mutex.synchronize do
        last_position = last_position_for(stream_name)
        expected_version = last_position if expected_version == :any
        stream = read_stream_events_forward(stream_name)
        raise WrongExpectedEventVersion unless last_position.equal?(expected_version)
        events.each do |event|
          raise EventDuplicatedInStream if stream.any?{|ev| ev.event_id.eql?(event.event_id) }
          if include_global
            raise EventDuplicatedInStream if @all.any?{|ev| ev.event_id.eql?(event.event_id) }
            @all.push(event)
          end
          stream.push(event)
        end
        @streams[stream_name] = stream
      end
      self
    end

    def last_position_for(stream_name)
      read_stream_events_forward(stream_name).size - POSITION_SHIFT
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
