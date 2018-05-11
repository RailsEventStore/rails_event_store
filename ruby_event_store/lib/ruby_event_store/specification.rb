module RubyEventStore
  class Specification
    NO_LIMIT = Object.new.freeze
    NO_BATCH = Object.new.freeze

    class Result < Struct.new(:direction, :start, :count, :stream, :batch_size)
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

      def batched?
        !batch_size.equal?(NO_BATCH)
      end
    end
    private_constant :Result

    attr_reader :result

    def initialize(repository, mapper, result = Result.new(:forward, :head, NO_LIMIT, Stream.new(GLOBAL_STREAM), NO_BATCH))
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
      if result.batched?
        Enumerator.new do |y|
          repository.read(result).each_slice(result.batch_size) do |batch|
            y << batch.map { |serialized_record| mapper.serialized_record_to_event(serialized_record) }
          end
        end
      else
        Enumerator.new do |y|
          repository.read(result).each do |serialized_record|
            y << mapper.serialized_record_to_event(serialized_record)
          end
        end
      end
    end

    def in_batches
      Specification.new(repository, mapper, result.dup.tap { |r| r.batch_size = 100 })
    end

    private
    attr_reader :repository, :mapper
  end
end
