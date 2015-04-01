module RailsEventStore
  module Actions
    class ReadAllEvents

      def initialize(repository)
        @repository = repository
      end

      def call(stream_name, direction)
        raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
        get_all_events(stream_name, direction)
      end

      private
      attr_reader :repository

      def get_all_events(stream_name, direction)
        if direction == :forward
          repository.load_all_events_forward(stream_name)
        else
          repository.load_all_events_backward(stream_name)
        end
      end
    end
  end
end