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

      def limit? = !to_h[:limit].nil?
      def limit = to_h[:limit] || Float::INFINITY
      def forward? = direction.equal?(:forward)
      def backward? = direction.equal?(:backward)
      def with_ids? = !with_ids.nil?
      def with_types? = !(with_types || []).empty?
      def batched? = read_as.equal?(:batch)
      def first? = read_as.equal?(:first)
      def last? = read_as.equal?(:last)
      def all? = read_as.equal?(:all)
      def time_sort_by_as_at? = time_sort_by.equal?(:as_at)
      def time_sort_by_as_of? = time_sort_by.equal?(:as_of)
    end
end
