module RubyEventStore
  class SpecificationResult
    def initialize(direction: :forward,
                   start: :head,
                   count: nil,
                   stream: Stream.new(GLOBAL_STREAM),
                   read_as: :all,
                   batch_size: Specification::DEFAULT_BATCH_SIZE)
      @result = Result.new(direction, start, count, stream, read_as, batch_size)
      freeze
    end

    # Results limit. True if number of read elements are limited
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def limit?
      !result.count.nil?
    end

    # Results limit. Limit count or infinity if limit not defined
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Integer|Infinity]
    def limit
      result.count || Float::INFINITY
    end

    # Stream definition. True if reading from global stream
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def global_stream?
      result.stream.global?
    end

    # Stream definition. Name of the stream to be read or nil
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [String|nil]
    def stream_name
      result.stream.name
    end

    # Starting position. True is starting from head
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def head?
      result.start.equal?(:head)
    end

    # Starting position. Event id of starting event or :head
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [String|Symbol]
    def start
      result.start
    end

    # Read direction. True is reading forward
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def forward?
      result.direction.equal?(:forward)
    end

    # Read direction. True is reading backward
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def backward?
      result.direction.equal?(:backward)
    end

    # Size of batch to read (only for :batch read strategy)
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Integer]
    def batch_size
      result.batch_size
    end

    # Read strategy. True if items will be read in batches
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def batched?
      result.read_as.equal?(:batch)
    end

    # Read strategy. True if first item will be read
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def first?
      result.read_as.equal?(:first)
    end

    # Read strategy. True if last item will be read
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def last?
      result.read_as.equal?(:last)
    end

    # Read strategy. True if all items will be read
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def all?
      result.read_as.equal?(:all)
    end

    # Clone [SpecificationResult]
    # If block is given cloned result might be modified.
    #
    # @return [SpecificationResult]
    def dup
      new_result = result.dup
      yield new_result if block_given?
      SpecificationResult.new(new_result.to_h)
    end

    # Two specification results are equal if:
    # * they are of the same class
    # * have identical data (verified with eql? method)
    #
    # @param other_spec [SpecificationResult, Object] object to compare
    #
    # @return [TrueClass, FalseClass]
    def ==(other_spec)
      other_spec.hash.eql?(hash)
    end

    # @private
    BIG_VALUE = 0b100010010100011110111101100001011111100101001010111110101000000

    # Generates a Fixnum hash value for this object. This function
    # have the property that a.eql?(b) implies a.hash == b.hash.
    #
    # The hash value is used along with eql? by the Hash class to
    # determine if two objects reference the same hash key.
    #
    # This hash is based on
    # * class
    # * direction
    # * start
    # * count
    # * stream
    # * read_as
    # * batch_size
    #
    # @return [Integer]
    def hash
      [
        self.class,
        result.direction,
        result.start,
        result.count,
        result.stream.hash,
        result.read_as,
        result.batch_size,
      ].hash ^ BIG_VALUE
    end
    private
    attr_reader :result

    Result = Struct.new(:direction, :start, :count, :stream, :read_as, :batch_size)
    private_constant :Result
  end
end
