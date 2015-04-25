require 'ostruct'

module RailsEventStore
  module Repositories
    class EventInMemoryRepository

      def initialize
        @db = []
      end
      attr_reader :db

      def find(condition)
        db.select { |event| event.event_id == condition[:event_id].to_s }.first
      end

      def create(model)
        model.merge!({id: db.length})
        db.push(OpenStruct.new(model))
      end

      def delete(condition)
        db.reject! { |event| event.stream == condition[:stream] }
      end

      def last_stream_event(stream_name)
        db.select { |event| event.stream == stream_name }.last
      end

      def load_all_events_forward(stream_name)
        db.select { |event| event.stream == stream_name }
      end

      def get_all_events
        db
      end

      def load_events_batch(stream_name, start_point, count)
        response = []
        db.each do |event|
          if event.stream == stream_name && event.id >= start_point && response.length < count
            response.push(event)
          end
        end
        response
      end

      def reset!
        db = []
      end

    end
  end
end
