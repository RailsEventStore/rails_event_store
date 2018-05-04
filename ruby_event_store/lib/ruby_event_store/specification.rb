module RubyEventStore
  class Specification
    NO_LIMIT = Object.new.freeze

    class Result < Struct.new(:direction, :start, :count, :stream)
      def limit?
        !count.equal?(NO_LIMIT)
      end

      def global_stream?
        stream.global?
      end

      def stream_name
        stream.name
      end

      def head?
        start.equal?(:head)
      end

      def forward?
        direction.equal?(:forward)
      end

      def backward?
        !forward?
      end
    end
    private_constant :Result

    attr_reader :result

    def initialize(repository, result = Result.new(:forward, :head, NO_LIMIT, Stream.new(GLOBAL_STREAM)))
      @repository  = repository
      @result = result
    end

    def stream(stream_name)
      result.stream = Stream.new(stream_name)
      Specification.new(repository, result)
    end

    def from(start)
      case start
      when Symbol
        raise InvalidPageStart unless [:head].include?(start)
      else
        raise InvalidPageStart if start.nil? || start.empty?
        raise EventNotFound.new(start) unless repository.has_event?(start)
      end
      result.start = start
      Specification.new(repository, result)
    end

    def forward
      result.direction = :forward
      Specification.new(repository, result)
    end

    def backward
      result.direction = :backward
      Specification.new(repository, result)
    end

    def limit(count)
      raise InvalidPageSize unless count && count > 0
      result.count = count
      Specification.new(repository, result)
    end

    def each
      repository.read(result)
    end

    private
    attr_reader :repository
  end
end
