module RailsEventStore
  module Repositories
    class EventRepository

      def initialize
        @adapter = ::RailsEventStore::Models::Event
      end
      attr_reader :adapter

      def find(condition)
        build_event_entity(adapter.where(condition).first)
      end

      def create(data)
        build_event_entity(adapter.create(data))
      rescue ActiveRecord::RecordNotUnique
        raise EventCannotBeSaved
      end

      def delete(condition)
        adapter.destroy_all condition
        nil
      end

      def get_all_events
        adapter.order('id ASC').order('stream').all.map(&method(:build_event_entity))
      end

      def last_stream_event(stream_name)
        build_event_entity(adapter.where(stream: stream_name).last)
      end

      def load_all_events_forward(stream_name)
        adapter.where(stream: stream_name).order('id ASC').map(&method(:build_event_entity))
      end

      def load_events_batch(stream_name, start_point, count)
        adapter.where('id >= ? AND stream = ?', start_point, stream_name).limit(count).map(&method(:build_event_entity))
      end

      private

      def build_event_entity(record)
        return nil unless record
        ::RailsEventStore::Event.new(record.data.merge(
          event_type: record.event_type,
          event_id:   record.event_id,
          stream:     record.stream,
          metadata:   record.metadata))
      end

    end
  end
end
