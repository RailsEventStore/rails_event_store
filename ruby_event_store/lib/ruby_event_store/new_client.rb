require "forwardable"

module RubyEventStore
  class NewClient

    extend Forwardable

    def_delegators :@old_client,
      :publish_event,
      :publish_events,
      :append_to_stream,
      :link_to_stream,
      :delete_stream,
      :read_events_forward,
      :read_events_backward,
      :read_all_streams_forward,
      :read_all_streams_backward,
      :read_event,
      :get_all_streams,
      :subscribe,
      :subscribe_to_all_events

    def initialize(repository:, metadata_proc: nil)
      @repository = repository
      @old_client = Client.new(repository: repository, metadata_proc: metadata_proc)
    end

    def read_stream_events_forward(stream_name)
      @old_client.send(:deserialized_events, read.stream(stream_name).forward.each)
    end

    def read_stream_events_backward(stream_name)
      read.stream(stream_name).backward.each.to_a
    end

    private

    def read
      Specification.new(@repository)
    end

    class Specification

      def initialize(repository)
        @repository = repository
      end

      def stream(stream_name)
        @stream_name = Stream.new(stream_name).name
        self
      end

      def forward
        @direction = :forward
        self
      end

      def backward
        @direction = :backward
        self
      end

      def each
        case @direction
        when :forward
          @repository.read_events_forward(Stream.new(@stream_name), :head, PAGE_SIZE).each
        when :backward
          @repository.read_events_backward(Stream.new(@stream_name), :head, PAGE_SIZE).each
        end
      end
    end
  end
end

