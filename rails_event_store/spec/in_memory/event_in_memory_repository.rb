require 'ostruct'

module RailsEventStore
  class EventInMemoryRepository

    def initialize
      @db = []
    end
    attr_reader :db

    def find(condition)
      build_event_entity db.select { |event| event.event_id == condition[:event_id].to_s }.first
    end

    def create(model)
      model.merge!({id: db.length})
      event = OpenStruct.new(model)
      db.push(event)
      build_event_entity(event)
    end

    def delete(condition)
      db.reject! { |event| event.stream == condition[:stream] }
      nil
    end

    def last_stream_event(stream_name)
      build_event_entity(db.select { |event| event.stream == stream_name }.last)
    end

    def load_all_events_forward(stream_name)
      db.select { |event| event.stream == stream_name }
        .map(&method(:build_event_entity))
    end

    def get_all_events
      db.map(&method(:build_event_entity))
    end

    def load_events_batch(stream_name, start_point, count)
      response = []
      db.each do |event|
        if event.stream == stream_name && event.id >= start_point && response.length < count
          response.push(event)
        end
      end
      response.map(&method(:build_event_entity))
    end

    private

    def build_event_entity(record)
      return nil unless record
      ::RailsEventStore::Event.new(record.data.merge(
        event_type: record.event_type,
        event_id:   record.event_id,
        metadata:   record.metadata))
    end
  end
end
