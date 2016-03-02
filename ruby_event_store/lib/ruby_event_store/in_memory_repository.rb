require 'ostruct'

module RubyEventStore
  class InMemoryRepository
    def initialize
      @all = Array.new
      @streams = Hash.new
    end

    def create(event, stream_name)
      stream = streams[stream_name] || Array.new
      all.push(event)
      stream.push(event)
      streams[stream_name] = stream
      event
    end

    def delete_stream(stream_name)
      removed = (streams[stream_name] || Array.new).map(&:event_id)
      @streams.reject!{|stream| stream == stream_name}
      @all.reject!{|ev| removed.include?(ev.event_id)}
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
      response = Array.new
      start_index = index_of(source, start_event_id) unless start_event_id.instance_of?(Symbol)
      source.each do |event|
        if (start_event_id.eql?(:head) || index_of(source, event.event_id) > start_index) && response.length < count
          response.push(event)
        end
      end
      response
    end

    def index_of(source, event_id)
      source.index{ |item| item.event_id.eql?(event_id) }
    end
  end
end
