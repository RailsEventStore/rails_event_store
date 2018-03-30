module RubyEventStore
  class Specification
    attr_reader :direction, :start, :count, :stream_name

    def initialize(repository)
      @repository  = repository
      @direction   = :forward
      @start       = :head
      @stream_name = GLOBAL_STREAM
    end

    def stream(stream_name)
      @stream_name = Stream.new(stream_name).name
      self
    end

    def from(start)
      @start = start
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
      @repository.read(self)
    end
  end
end
