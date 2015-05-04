module RailsEventStore
  module Repositories
    class EventRepository

      def initialize
        @adapter = EventEntity
      end
      attr_reader :adapter

      def find(condition)
        adapter.where(condition).first
      end

      def create(data)
        model = adapter.new(data)
        raise EventCannotBeSaved unless model.valid?
        model.save
      end

      def delete(condition)
        adapter.destroy_all condition
      end

      def get_all_events
        adapter.find(:all, order: 'stream').map &method(:map_record)
      end

      def last_stream_event(stream_name)
        adapter.where(stream: stream_name).last.map &method(:map_record)
      end

      def load_all_events_forward(stream_name)
        adapter.where(stream: stream_name).order('id ASC').map &method(:map_record)
      end

      def load_events_batch(stream_name, start_point, count)
        adapter.where('id >= ? AND stream = ?', start_point, stream_name).limit(count).map &method(:map_record)
      end

      private

      def map_record(record)
        event_data = {
            stream:     record.stream,
            event_type: record.event_type,
            event_id:   record.event_id,
            metadata:   record.metadata,
            data:       record.data
        }
        OpenStruct.new(event_data)
      end
    end
  end
end
