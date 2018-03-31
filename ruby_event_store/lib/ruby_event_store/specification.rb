module RubyEventStore
  class Specification
    NO_LIMIT = Object.new.freeze
    Result = Struct.new(:direction, :start, :count, :stream)

    attr_reader :result

    def initialize(repository)
      @repository  = repository
      @result = Result.new(:forward, :head, NO_LIMIT, Stream.new(GLOBAL_STREAM))
    end

    def stream(stream_name)
      result.stream = Stream.new(stream_name)
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
      result.start = start
      self
    end

    def forward
      result.direction = :forward
      self
    end

    def backward
      result.direction = :backward
      self
    end

    def limit(count)
      raise InvalidPageSize unless count && count > 0
      result.count = count
      self
    end

    def each
      @repository.read(result)
    end
  end
end
