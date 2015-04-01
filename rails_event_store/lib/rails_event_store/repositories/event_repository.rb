module RailsEventStore
  module Repositories
    class EventRepository < Repository

      def initialize(adapter = Models::Event)
        super adapter
      end

      def last_stream_event(stream_name)
        adapter.where(stream: stream_name).last
      end

      def load_all_events_forward(stream_name)
        adapter.where(stream: stream_name).order('id ASC')
      end

      def load_all_events_backward(stream_name)
        adapter.where(stream: stream_name).order('id DESC')
      end

      def load_events_batch(stream_name, start_point, count)
        adapter.where('id >= ? AND stream = ?', start_point, stream_name).limit(count)
      end
    end
  end
end