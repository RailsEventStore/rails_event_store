require 'ostruct'

module RubyEventStore
  class InMemoryRepository
    def initialize
      @all = Array.new
      @streams = Hash.new
    end

    def create(event, stream_name)
      stream = read_stream_events_forward(stream_name)
      all.push(event)
      stream.push(event)
      streams[stream_name] = stream
      event
    end

    def delete_stream(stream_name)
      removed = read_stream_events_forward(stream_name).map(&:event_id)
      streams.delete(stream_name)
      all.delete_if{|ev| removed.include?(ev.event_id)}
    end

    def has_event?(event_id)
      all.any?{ |item| item.event_id.eql?(event_id) }
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
      streams[stream_name] || Array.new
    end

    def read_stream_events_backward(stream_name)
      read_stream_events_forward(stream_name).reverse
    end

    def read_all_streams_forward(start_event_id, count)
      read_batch(all, start_event_id, count)
    end

    def read_all_streams_backward(start_event_id, count)
      read_batch(all.reverse, start_event_id, count)
    end

    private
    attr_accessor :streams, :all

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
