require 'ostruct'

module RubyEventStore
  class InMemoryRepository

    def initialize
      @db = []
    end
    attr_reader :db

    def create(event, stream_name)
      model = {index: db.length, stream: stream_name, event: event}
      db.push(model)
      event
    end

    def delete_stream(stream_name)
      db.reject! { |item| item[:stream] == stream_name }
    end

    def has_event?(event_id)
      db.any?{ |item| item[:event].event_id == event_id }
    end

    def last_stream_event(stream_name)
      read_stream_events_forward(stream_name).last
    end

    def read_events_forward(stream_name, start_event_id, count)
      source = read_stream_events_forward(stream_name)
      read_batch(source, start_event_id, count, ->(a,b) { a > b })
    end

    def read_events_backward(stream_name, start_event_id, count)
      source = read_stream_events_backward(stream_name)
      read_batch(source, start_event_id, count, ->(a,b) { a < b })
    end

    def read_stream_events_forward(stream_name)
      db.select { |item| item[:stream] == stream_name }
        .map{ |item| item[:event] }
    end

    def read_stream_events_backward(stream_name)
      read_stream_events_forward(stream_name).reverse
    end

    def read_all_streams_forward(start_event_id, count)
      read_batch(db.map{ |item| item[:event] }, start_event_id, count, ->(a,b) { a > b })
    end

    def read_all_streams_backward(start_event_id, count)
      read_batch(db.map{ |item| item[:event] }.reverse, start_event_id, count, ->(a,b) { a < b })
    end

    def reset!
      @db = []
    end

    private
    def read_batch(source, start_event_id, count, comparision)
      response = []
      start_index = start_event_id.is_a?(Symbol) ? nil : index_of(start_event_id)
      source.each do |event|
        if (start_index.nil? || comparision.(index_of(event.event_id), start_index)) && response.length < count
          response.push(event)
        end
      end
      response
    end

    def index_of(event_id)
      db.select { |item| item[:event].event_id == event_id.to_s }.first[:index]
    end
  end
end
