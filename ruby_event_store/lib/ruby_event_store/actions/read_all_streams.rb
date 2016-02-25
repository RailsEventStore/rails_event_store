module RubyEventStore
  module Actions
    class ReadAllStreams

      def initialize(repository)
        @repository = repository
      end

      def call
        repository.get_all_events
      end

      private
      attr_reader :repository
    end
  end
end
