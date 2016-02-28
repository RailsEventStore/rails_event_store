require 'ostruct'

module RubyEventStore
  class InMemoryRepository

    def initialize
      @db = []
    end
    attr_reader :db

    def find(condition)
      db.select { |event| event.event_id == condition[:event_id].to_s }.first
    end

    def create(model)
      model.merge!({id: db.length})
      event = OpenStruct.new(model)
      db.push(event)
      event
    end

    def delete_stream(stream_name)
      db.reject! { |event| event.stream == stream_name }
    end

    def has_event?(event_id)
      db.any?{|event| event.event_id == event_id}
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
      db.select { |event| event.stream == stream_name }
    end

    def read_stream_events_backward(stream_name)
      read_stream_events_forward(stream_name).reverse
    end

    def read_all_streams_forward(start_event_id, count)
      read_batch(db, start_event_id, count)
    end

    def read_all_streams_forward(start_event_id, count)
      read_batch(db.reverse, start_event_id, count)
    end

    def reset!
      @db = []
    end

    private
    def read_batch(source, start_event_id, count)
      response = []
      source.each do |event|
        if (start_event_id.nil? || event.id > start_event_id) && response.length < count
          response.push(event)
        end
      end
      response
    end
  end
end
