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

    def initialize(repository, mapper, result = Result.new(:forward, :head, NO_LIMIT, Stream.new(GLOBAL_STREAM)))
      @mapper = mapper
      @repository  = repository
      @result = result
    end

    def stream(stream_name)
      Specification.new(repository, mapper, result.dup.tap { |r| r.stream = Stream.new(stream_name) })
    end

    def from(start)
      case start
      when Symbol
        raise InvalidPageStart unless [:head].include?(start)
      else
        raise InvalidPageStart if start.nil? || start.empty?
        raise EventNotFound.new(start) unless repository.has_event?(start)
      end
      Specification.new(repository, mapper, result.dup.tap { |r| r.start = start })
    end

    def forward
      Specification.new(repository, mapper, result.dup.tap { |r| r.direction = :forward })
    end

    def backward
      Specification.new(repository, mapper, result.dup.tap { |r| r.direction = :backward })
    end

    def limit(count)
      raise InvalidPageSize unless count && count > 0
      Specification.new(repository, mapper, result.dup.tap { |r| r.count = count })
    end

    def each
      Enumerator.new do |y|
        repository.read(result).each do |sev|
          y << mapper.serialized_record_to_event(sev)
        end
      end
    end

    private
    attr_reader :repository, :mapper
  end
end
