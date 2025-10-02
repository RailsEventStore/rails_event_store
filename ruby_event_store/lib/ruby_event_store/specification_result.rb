# frozen_string_literal: true

module RubyEventStore
  SpecificationResult =
    Data.define(
      :direction,
      :start,
      :stop,
      :older_than,
      :older_than_or_equal,
      :newer_than,
      :newer_than_or_equal,
      :time_sort_by,
      :limit,
      :stream,
      :read_as,
      :batch_size,
      :with_ids,
      :with_types,
    ) do
      def initialize(
        direction: :forward,
        start: nil,
        stop: nil,
        older_than: nil,
        older_than_or_equal: nil,
        newer_than: nil,
        newer_than_or_equal: nil,
        time_sort_by: nil,
        limit: nil,
        stream: Stream.new(GLOBAL_STREAM),
        read_as: :all,
        batch_size: Specification::DEFAULT_BATCH_SIZE,
        with_ids: nil,
        with_types: nil
      )
        super
      end

      # Limited results. True if number of read elements are limited
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Boolean]
      def limit?
        !to_h[:limit].nil?
      end

      # Results limit or infinity if limit not defined
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Integer|Infinity]
      def limit = to_h[:limit] || Float::INFINITY

      # Stream definition. Stream to be read or nil
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Stream|nil]
      # def stream = super

      # Starting position. Event id of starting event
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [String]
      # def start = super

      # Stop position. Event id of stopping event
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [String|Symbol]
      # def stop = super

      # Ending time.
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Time]
      # def older_than = super

      # Ending time.
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Time]
      # def older_than_or_equal = super

      # Starting time.
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Time]
      # def newer_than = super

      # Starting time.
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Time]
      # def newer_than_or_equal = super

      # Time sorting strategy. Nil when not specified.
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Symbol]
      # def time_sort_by = super

      # Read direction. True is reading forward
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Boolean]
      def forward? = direction.equal?(:forward)

      # Read direction. True is reading backward
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Boolean]
      def backward? = direction.equal?(:backward)

      # Size of batch to read (only for :batch read strategy)
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Integer]
      # def batch_size = super

      # Ids of specified event to be read (if any given)
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Array|nil]
      # def with_ids = super

      # Read by specified ids. True if event ids have been specified.
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Boolean]
      def with_ids? = !with_ids.nil?

      # Event types to be read (if any given)
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Array|nil]
      # def with_types = self.with_types&.map(&:to_s)

      # Read by specified event types. True if event types have been specified.
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Boolean]
      def with_types? = !(with_types || []).empty?

      # Read strategy. True if items will be read in batches
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Boolean]
      def batched? = read_as.equal?(:batch)

      # Read strategy. True if first item will be read
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Boolean]
      def first? = read_as.equal?(:first)

      # Read strategy. True if last item will be read
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Boolean]
      def last? = read_as.equal?(:last)

      # Read strategy. True if all items will be read
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Boolean]
      def all? = read_as.equal?(:all)

      # Read strategy. True if results will be sorted by timestamp
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Boolean]
      def time_sort_by_as_at? = time_sort_by.equal?(:as_at)

      # Read strategy. True if results will be sorted by valid_at
      # {http://railseventstore.org/docs/read/ Find out more}.
      #
      # @return [Boolean]
      def time_sort_by_as_of? = time_sort_by.equal?(:as_of)
    end
end
