module RailsEventStore
  module Actions
    class ReadAllEvents

      def initialize(repository)
        @repository = repository
      end

      def call(stream_name)
        raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
        get_all_events(stream_name)
      end

      private
      attr_reader :repository

      def get_all_events(stream_name)
        repository.load_all_events_forward(stream_name)
      end
    end
  end
end
