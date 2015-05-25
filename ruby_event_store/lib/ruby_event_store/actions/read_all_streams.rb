module RubyEventStore
  module Actions
    class ReadAllStreams

      def initialize(repository)
        @repository = repository
      end

      def call
        get_all_events.group_by { |event| event.stream }
      end

      private
      attr_reader :repository

      def get_all_events
        repository.get_all_events
      end
    end
  end
end
