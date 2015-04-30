module RailsEventStore
  module Actions
    class AppendEventToStream

      def initialize(repository)
        @repository = repository
      end

      def call(stream_name, event, expected_version)
        raise WrongExpectedEventVersion if version_incorrect?(stream_name, expected_version)
        event.validate!
        save_event(event, stream_name)
        event
      end

      private
      attr_reader :repository

      def version_incorrect?(stream_name, expected_version)
        unless expected_version.nil?
          find_last_event_version(stream_name) != expected_version
        end
      end

      def find_last_event_version(stream_name)
        repository.last_stream_event(stream_name).event_id
      end

      def save_event(event, stream_name)
        repository.create(event.to_h.merge!(stream: stream_name))
      end
    end
  end
end
