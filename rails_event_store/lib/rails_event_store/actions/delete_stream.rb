module EventStore
  module Actions
    class DeleteStream

      def initialize(repository)
        @repository = repository
      end

      def call(stream_name)
        raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
        delete_stream(stream_name)
      end

      private
      attr_reader :repository

      def delete_stream(stream_name)
        repository.delete({stream: stream_name})
      end
    end
  end
end