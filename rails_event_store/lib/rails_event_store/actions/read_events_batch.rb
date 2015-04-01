module RailsEventStore
  module Actions
    class ReadEventsBatch

      def initialize(repository)
        @repository = repository
      end

      def call(stream_name, start, count, direction)
        raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
        event = find_event(start)
        get_events_batch(stream_name, event.id, count, direction)
      end

      private
      attr_reader :repository

      def get_events_batch(stream_name, start, count, direction)
        unless direction != :forward
          repository.load_events_batch(stream_name, start, count)
        else
          repository.load_events_batch(stream_name, start, count).reverse
        end
      end

      def find_event(start)
        event = repository.find({event_id: start})
        raise EventNotFound if event.nil?
        event
      end
    end
  end
end