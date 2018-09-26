module RubyEventStore
  class SpecificationResult
    def initialize(direction: :forward,
                   start: :head,
                   count: nil,
                   stream: Stream.new(GLOBAL_STREAM),
                   read_as: :all,
                   batch_size: Specification::DEFAULT_BATCH_SIZE)
      @attributes = Struct.new(:direction, :start, :count, :stream, :read_as, :batch_size)
        .new(direction, start, count, stream, read_as, batch_size)
      freeze
    end

    # Limited results. True if number of read elements are limited
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def limit?
      !attributes.count.nil?
    end

    # Results limit or infinity if limit not defined
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Integer|Infinity]
    def limit
      attributes.count || Float::INFINITY
    end

    # Stream definition. Stream to be read or nil
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Stream|nil]
    def stream
      attributes.stream
    end

    # Starting position. True is starting from head
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def head?
      start.equal?(:head)
    end

    # Starting position. Event id of starting event or :head
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [String|Symbol]
    def start
      attributes.start
    end

    # Read direction. True is reading forward
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def forward?
      get_direction.equal?(:forward)
    end

    # Read direction. True is reading backward
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def backward?
      get_direction.equal?(:backward)
    end

    # Size of batch to read (only for :batch read strategy)
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Integer]
    def batch_size
      attributes.batch_size
    end

    # Read strategy. True if items will be read in batches
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def batched?
      attributes.read_as.equal?(:batch)
    end

    # Read strategy. True if first item will be read
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def first?
      attributes.read_as.equal?(:first)
    end

    # Read strategy. True if last item will be read
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def last?
      attributes.read_as.equal?(:last)
    end

    # Read strategy. True if all items will be read
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def all?
      attributes.read_as.equal?(:all)
    end

    # Clone [SpecificationResult]
    # If block is given cloned attributes might be modified.
    #
    # @return [SpecificationResult]
    def dup
      new_attributes = attributes.dup
      yield new_attributes if block_given?
      SpecificationResult.new(new_attributes.to_h)
    end

    # Two specification attributess are equal if:
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
        get_direction,
        start,
        limit,
        stream,
        attributes.read_as,
        batch_size,
      ].hash ^ BIG_VALUE
    end

    # @deprecated Use {#limit} instead. {https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.32.0 More info}
    def count
      warn <<~EOW
        RubyEventStore::SpecificationResult#count has been deprecated.
        Use RubyEventStore::SpecificationResult#limit instead.
      EOW
      limit
    end

    # @deprecated Use {#forward?} or {#backward?} instead. {https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.32.0 More info}
    def direction
      warn <<~EOW
        RubyEventStore::SpecificationResult#direction has been deprecated.
        Use RubyEventStore::SpecificationResult#forward? or
        RubyEventStore::SpecificationResult#backward? instead.
      EOW
      get_direction
    end

    # @deprecated Use {#stream.name} instead. {https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.32.0 More info}
    def stream_name
      warn <<~EOW
        RubyEventStore::SpecificationResult#stream_name has been deprecated.
        Use RubyEventStore::SpecificationResult#stream.name instead.
      EOW
      stream.name
    end

    # @deprecated Use {#stream.global?} instead. {https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.32.0 More info}
    def global_stream?
      warn <<~EOW
        RubyEventStore::SpecificationResult#global_stream? has been deprecated.
        Use RubyEventStore::SpecificationResult#stream.global? instead.
      EOW
      stream.global?
    end

    private
    attr_reader :attributes

    def get_direction
      attributes.direction
    end
  end
end
