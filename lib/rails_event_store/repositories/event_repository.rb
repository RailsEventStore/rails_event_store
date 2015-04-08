module RailsEventStore
  module Repositories
    class EventRepository < Repository

      def initialize(adapter = Models::Event)
        super adapter
      end

      def gel_all_events
        adapter.find(:all, order: 'stream').map &method(:map_record)
      end

      def last_stream_event(stream_name)
        adapter.where(stream: stream_name).last.map &method(:map_record)
      end

      def load_all_events_forward(stream_name)
        adapter.where(stream: stream_name).order('id ASC').map &method(:map_record)
      end

      def load_all_events_backward(stream_name)
        adapter.where(stream: stream_name).order('id DESC').map &method(:map_record)
      end

      def load_events_batch(stream_name, start_point, count)
        adapter.where('id >= ? AND stream = ?', start_point, stream_name).limit(count).map &method(:map_record)
      end

      private

      def map_record(record)
        Models::EventEntity.new.tap do |event|
          event.stream     = record.stream
          event.event_type = record.event_type
          event.event_id   = record.event_id
          event.metadata   = record.metadata
          event.data       = record.data
        end
      end
    end
  end
end
