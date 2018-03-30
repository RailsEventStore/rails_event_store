module RubyEventStore
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
