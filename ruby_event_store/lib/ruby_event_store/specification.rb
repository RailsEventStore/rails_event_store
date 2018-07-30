module RubyEventStore

  # Used for building and executing the query specification.
  class Specification
    DEFAULT_BATCH_SIZE = 100

    attr_reader :start, :batch_size
    def limit?
      !@count.nil?
    end

    def count
      @count || Float::INFINITY
    end

    def global_stream?
      @stream.global?
    end

    def stream_name
      @stream.name
    end

    def head?
      @start.equal?(:head)
    end

    def forward?
      @direction.equal?(:forward)
    end

    def backward?
      !forward?
    end

    def all?
      @read_as.equal?(:all)
    end

    def batched?
      @read_as.equal?(:batch)
    end

    def first?
      @read_as.equal?(:first)
    end

    def last?
      @read_as.equal?(:last)
    end

    def initialize(repository, mapper,
                   direction: :forward,
                   start: :head,
                   count: nil,
                   stream: Stream.new(GLOBAL_STREAM),
                   read_as: :all,
                   batch_size: DEFAULT_BATCH_SIZE)
      @mapper = mapper
      @repository  = repository
      @direction = direction
      @start = start
      @count = count
      @stream = stream
      @read_as = read_as
      @batch_size = batch_size
      freeze
    end

    # Limits the query to certain stream.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @param name [String] name of the stream to get events from
    # @return [Specification]
    def stream(name)
      Specification.new(repository, mapper,
                        direction: @direction,
                        start: @start,
                        count: @count,
                        stream: Stream.new(name),
                        read_as: @read_as,
                        batch_size: @batch_size)
    end

    # Limits the query to events before or after another event.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @param start [:head, String] id of event to start reading from.
    #   :head can mean the beginning or end of the stream, depending on the
    #   #direction
    # @return [Specification]
    def from(start)
      case start
      when Symbol
        raise InvalidPageStart unless [:head].include?(start)
      else
        raise InvalidPageStart if start.nil? || start.empty?
        raise EventNotFound.new(start) unless repository.has_event?(start)
      end
      Specification.new(repository, mapper,
                        direction: @direction,
                        start: start,
                        count: @count,
                        stream: @stream,
                        read_as: @read_as,
                        batch_size: @batch_size)
    end

    # Sets the order of reading events to ascending (forward from the start).
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Specification]
    def forward
      Specification.new(repository, mapper,
                        direction: :forward,
                        start: @start,
                        count: @count,
                        stream: @stream,
                        read_as: @read_as,
                        batch_size: @batch_size)
    end

    # Sets the order of reading events to descending (backward from the start).
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Specification]
    def backward
      Specification.new(repository, mapper,
                        direction: :backward,
                        start: @start,
                        count: @count,
                        stream: @stream,
                        read_as: @read_as,
                        batch_size: @batch_size)
    end

    # Limits the query to specified number of events.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @param count [Integer] maximal number of events to retrieve
    # @return [Specification]
    def limit(count)
      raise InvalidPageSize unless count && count > 0
      Specification.new(repository, mapper,
                        direction: @direction,
                        start: @start,
                        count: count,
                        stream: @stream,
                        read_as: @read_as,
                        batch_size: @batch_size)
    end

    # Executes the query based on the specification built up to this point.
    # Yields each batch of records that was retrieved from the store.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @yield [Array<Event, Proto>] batch of events
    # @return [Enumerator, nil] Enumerator is returned when block not given
    def each_batch
      return to_enum(:each_batch) unless block_given?

      repository.read(batched? ? self : in_batches).each do |batch|
        yield batch.map { |serialized_record| mapper.serialized_record_to_event(serialized_record) }
      end
    end

    # Executes the query based on the specification built up to this point.
    # Yields events read from the store if block given. Otherwise, returns enumerable collection.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @yield [Event, Proto] event
    # @return [Enumerator, nil] Enumerator is returned when block not given
    def each
      return to_enum unless block_given?

      each_batch do |batch|
        batch.each { |event| yield event }
      end
    end

    # Specifies that events should be obtained in batches.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # Looping through a collection of events from the store
    # can be inefficient since it will try to instantiate all
    # the events at once.
    #
    # In that case, batch processing methods allow you to work
    # with the records in batches, thereby greatly reducing
    # memory consumption.
    #
    # @param batch_size [Integer] number of events to read in a single batch
    # @return [Specification]
    def in_batches(batch_size = DEFAULT_BATCH_SIZE)
      Specification.new(repository, mapper,
                        direction: @direction,
                        start: @start,
                        count: @count,
                        stream: @stream,
                        read_as: :batch,
                        batch_size: batch_size)
    end
    alias :in_batches_of :in_batches

    # Specifies that only first event should be read.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Specification]
    def read_first
      Specification.new(repository, mapper,
                        direction: @direction,
                        start: @start,
                        count: @count,
                        stream: @stream,
                        read_as: :first,
                        batch_size: @batch_size)
    end

    # Specifies that only last event should be read.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Specification]
    def read_last
      Specification.new(repository, mapper,
                        direction: @direction,
                        start: @start,
                        count: @count,
                        stream: @stream,
                        read_as: :last,
                        batch_size: @batch_size)
    end

    # Executes the query based on the specification built up to this point.
    # Returns the first event in specified collection of events.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Event, nil]
    def first
      record = repository.read(read_first)
      mapper.serialized_record_to_event(record) if record
    end

    # Executes the query based on the specification built up to this point.
    # Returns the last event in specified collection of events.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Event, nil]
    def last
      record = repository.read(read_last)
      mapper.serialized_record_to_event(record) if record
    end

    # Two read specifications are equal if:
    # * they are of the same class
    # * have identical data (verified with eql? method)
    #
    # @param other_spec [Specification, Object] object to compare
    #
    # @return [TrueClass, FalseClass]
    def ==(other_spec)
      other_spec.instance_of?(self.class) &&
        other_spec.count.eql?(count) &&
        other_spec.stream_name.eql?(stream_name) &&
        other_spec.head?.eql?(head?) &&
        other_spec.forward?.eql?(forward?) &&
        other_spec.batched?.eql?(batched?) &&
        other_spec.first?.eql?(first?) &&
        other_spec.last?.eql?(last?)
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
    # * stream_name
    # * head?
    # * forward?
    # * batched?
    # * first?
    # * last?
    def hash
      [
        self.class,
        count,
        stream_name,
        head?,
        forward?,
        batched?,
        first?,
        last?,
      ].hash ^ BIG_VALUE
    end

    private
    attr_reader :repository, :mapper
  end
end
