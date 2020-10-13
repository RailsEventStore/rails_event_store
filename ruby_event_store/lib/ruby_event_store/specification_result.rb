# frozen_string_literal: true

module RubyEventStore
  class SpecificationResult
    def initialize(direction: :forward,
                   start: nil,
                   stop: nil,
                   older_than: nil,
                   older_than_or_equal: nil,
                   newer_than: nil,
                   newer_than_or_equal: nil,
                   time_sort_by: nil,
                   count: nil,
                   stream: Stream.new(GLOBAL_STREAM),
                   read_as: :all,
                   batch_size: Specification::DEFAULT_BATCH_SIZE,
                   with_ids: nil,
                   with_types: nil)
      @attributes = Struct.new(
        :direction,
        :start,
        :stop,
        :older_than,
        :older_than_or_equal,
        :newer_than,
        :newer_than_or_equal,
        :time_sort_by,
        :count,
        :stream,
        :read_as,
        :batch_size,
        :with_ids,
        :with_types
      ).new(
        direction,
        start,
        stop,
        older_than,
        older_than_or_equal,
        newer_than,
        newer_than_or_equal,
        time_sort_by,
        count,
        stream,
        read_as,
        batch_size,
        with_ids,
        with_types
      )
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

    # Starting position. Event id of starting event
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [String]
    def start
      attributes.start
    end

    # Stop position. Event id of stopping event
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [String|Symbol]
    def stop
      attributes.stop
    end

    # Ending time.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Time]
    def older_than
      attributes.older_than
    end

    # Ending time.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Time]
    def older_than_or_equal
      attributes.older_than_or_equal
    end

    # Starting time.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Time]
    def newer_than
      attributes.newer_than
    end

    # Starting time.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Time]
    def newer_than_or_equal
      attributes.newer_than_or_equal
    end

    # Time sorting strategy. Nil when not specified.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Symbol]
    def time_sort_by
      attributes.time_sort_by
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

    # Ids of specified event to be read (if any given)
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Array|nil]
    def with_ids
      attributes.with_ids
    end

    # Read by specified ids. True if event ids have been specified.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def with_ids?
      !with_ids.nil?
    end

    # Event types to be read (if any given)
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Array|nil]
    def with_types
      attributes.with_types&.map(&:to_s)
    end

    # Read by specified event types. True if event types have been specified.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Boolean]
    def with_types?
      !(with_types || []).empty?
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
      SpecificationResult.new(**new_attributes.to_h)
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
    # * stop
    # * older_than
    # * older_than_or_equal
    # * newer_than
    # * newer_than_or_equal
    # * time_sort_by
    # * count
    # * stream
    # * read_as
    # * batch_size
    # * with_ids
    # * with_types
    #
    # @return [Integer]
    def hash
      [
        self.class,
        get_direction,
        start,
        stop,
        older_than,
        older_than_or_equal,
        newer_than,
        newer_than_or_equal,
        time_sort_by,
        limit,
        stream,
        attributes.read_as,
        batch_size,
        with_ids,
        with_types,
      ].hash ^ BIG_VALUE
    end

    private
    attr_reader :attributes

    def get_direction
      attributes.direction
    end
  end
end
