module RubyEventStore

  # Used for building and executing the query specification.
  class Specification
    DEFAULT_BATCH_SIZE = 100

    class Result < Struct.new(:direction, :start, :count, :stream, :read_as, :batch_size)
      def limit?
        !count.nil?
      end

      def limit
        count || Float::INFINITY
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
        read_as.equal?(:batch)
      end

      def first?
        read_as.equal?(:first)
      end

      def last?
        read_as.equal?(:last)
      end
    end
    private_constant :Result

    # @api private
    # @private
    attr_reader :result

    # @api private
    # @private
    def initialize(reader, result = Result.new(:forward, :head, nil, Stream.new(GLOBAL_STREAM), :all, DEFAULT_BATCH_SIZE))
      @reader = reader
      @result = result
    end

    # Limits the query to certain stream.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @param stream_name [String] name of the stream to get events from
    # @return [Specification]
    def stream(stream_name)
      Specification.new(reader, result.dup.tap { |r| r.stream = Stream.new(stream_name) })
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
        raise EventNotFound.new(start) unless reader.has_event?(start)
      end
      Specification.new(reader, result.dup.tap { |r| r.start = start })
    end

    # Sets the order of reading events to ascending (forward from the start).
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Specification]
    def forward
      Specification.new(reader, result.dup.tap { |r| r.direction = :forward })
    end

    # Sets the order of reading events to descending (backward from the start).
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Specification]
    def backward
      Specification.new(reader, result.dup.tap { |r| r.direction = :backward })
    end

    # Limits the query to specified number of events.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @param count [Integer] maximal number of events to retrieve
    # @return [Specification]
    def limit(count)
      raise InvalidPageSize unless count && count > 0
      Specification.new(reader, result.dup.tap { |r| r.count = count })
    end

    # Executes the query based on the specification built up to this point.
    # Yields each batch of records that was retrieved from the store.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @yield [Array<Event, Proto>] batch of events
    # @return [Enumerator, nil] Enumerator is returned when block not given
    def each_batch
      return to_enum(:each_batch) unless block_given?

      reader.each(result.tap { |r| r.read_as = :batch }) do |batch|
        yield batch
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
      Specification.new(reader, result.dup.tap { |r| r.read_as = :batch; r.batch_size = batch_size })
    end
    alias :in_batches_of :in_batches

    # Specifies that only first event should be read.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Specification]
    def read_first
      Specification.new(reader, result.dup.tap { |r| r.read_as = :first })
    end

    # Specifies that only last event should be read.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Specification]
    def read_last
      Specification.new(reader, result.dup.tap { |r| r.read_as = :last })
    end

    # Executes the query based on the specification built up to this point.
    # Returns the first event in specified collection of events.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Event, nil]
    def first
      reader.single(read_first.result)
    end

    # Executes the query based on the specification built up to this point.
    # Returns the last event in specified collection of events.
    # {http://railseventstore.org/docs/read/ Find out more}.
    #
    # @return [Event, nil]
    def last
      reader.single(read_last.result)
    end

    private
    attr_reader :reader
  end
end
