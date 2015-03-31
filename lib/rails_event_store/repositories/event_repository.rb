module RailsEventStore
  module Repositories
    class EventRepository < Repository

      def initialize(adapter = Models::Event)
        super adapter
      end

      def last_stream_event(stream_name)
        adapter.where(stream: stream_name).last
      end
    end
  end
end