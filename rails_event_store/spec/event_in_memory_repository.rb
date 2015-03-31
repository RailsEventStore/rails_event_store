require 'ostruct'

module RailsEventStore
  class EventInMemoryRepository

    def initialize
      @db = []
    end
    attr_reader :db

    def create(model)
      db.push(OpenStruct.new(model))
    end

    def delete(stream_name)
      db.reject! { |event| event.stream == stream_name }
    end

    def last_stream_event(stream_name)
      db.select { |event| event.stream == stream_name }.last
    end

    def reset!
      db = []
    end

  end
end