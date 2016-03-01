require 'ostruct'

module RubyEventStore
  class InMemoryRepository

    def initialize
      reset!
    end
    attr_reader :db

    def create(event, stream_name)
      model = {index: db.length, stream: stream_name, event: event}
      db.push(model)
      event
    end

    def delete_stream(stream_name)
      db.reject! { |item| item.fetch(:stream) == stream_name }
    end

    def has_event?(event_id)
      db.any?{ |item| item.fetch(:event).event_id == event_id }
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
      db.select { |item| item.fetch(:stream) == stream_name }
        .map{ |item| item.fetch(:event) }
    end

    def read_stream_events_backward(stream_name)
      read_stream_events_forward(stream_name).reverse
    end

    def read_all_streams_forward(start_event_id, count)
      read_batch(db.map{ |item| item.fetch(:event) }, start_event_id, count, ->(a,b) { a > b })
    end

    def read_all_streams_backward(start_event_id, count)
      read_batch(db.map{ |item| item.fetch(:event) }.reverse, start_event_id, count, ->(a,b) { a < b })
    end

    def reset!
      @db = Array.new
    end

    private
    def read_batch(source, start_event_id, count, comparision)
      response = Array.new
      start_index = index_of(start_event_id) unless start_event_id.instance_of?(Symbol)
      source.each do |event|
        if (start_event_id == :head || comparision.(index_of(event.event_id), start_index)) && response.length < count
          response.push(event)
        end
      end
      response
    end

    def index_of(event_id)
      db.select { |item| item.fetch(:event).event_id == event_id }.first.fetch(:index)
    end
  end
end
