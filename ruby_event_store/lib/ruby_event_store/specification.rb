module RubyEventStore
  class Specification
    NO_LIMIT = Object.new.freeze

    attr_reader :direction, :start, :count, :stream_name

    def initialize(repository)
      @repository  = repository
      @direction   = :forward
      @start       = :head
      @stream_name = GLOBAL_STREAM
      @count       = NO_LIMIT
    end

    def stream(stream_name)
      @stream_name = Stream.new(stream_name).name
      self
    end

    def from(start)
      case start
      when Symbol
        raise InvalidPageStart unless [:head].include?(start)
      else
        raise InvalidPageStart if start.nil? || start.empty?
        raise EventNotFound.new(start) unless @repository.has_event?(start)
      end
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

    def limit(count)
      raise InvalidPageSize unless count && count > 0
      @count = count
      self
    end

    def each
      @repository.read(self)
    end

    private

    def non_head_symbol(symbol)
      !((Symbol === symbol) || [:head].include?(start))
    end
  end
end
