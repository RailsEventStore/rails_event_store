# frozen_string_literal: true

require "set"

module RubyEventStore
  # In-process set of tombstoned streams. Used by StreamMetadataAwareRepository to refuse appends
  # whose expected version gives no read of the stream to take the tombstone flag from.
  #
  # It learns of tombstones written by this process at once, and of those written by other
  # processes on the first lookup after ttl seconds: then it reads, from the global stream, the
  # StreamTombstoned events written since the last one it saw. A tombstone is never undone,
  # so the set only grows.
  class StreamMetadataRegistry
    BATCH_SIZE = 1_000
    private_constant :BATCH_SIZE

    def initialize(repository, ttl: 5, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      @repository = repository
      @ttl = ttl
      @clock = clock
      @tombstoned = Set.new
      @mutex = Mutex.new
    end

    def tombstoned?(stream)
      mutex.synchronize do
        refresh if stale?
        tombstoned.include?(stream.name)
      end
    end

    def tombstone(stream)
      mutex.synchronize { tombstoned.add(stream.name) }
    end

    private

    attr_reader :repository, :ttl, :clock, :tombstoned, :mutex

    def stale?
      @refreshed_at.nil? || clock.call - @refreshed_at >= ttl
    end

    def refresh
      started_at = clock.call
      repository
        .read(tombstones_since(@last_event_id))
        .each do |records|
          records.each { |record| tombstoned.add(record.data.fetch("stream")) }
          @last_event_id = records.last.event_id
        end
      @refreshed_at = started_at
    end

    def tombstones_since(event_id)
      specification = Specification.new(nil).of_type(StreamMetadataEvents::StreamTombstoned).in_batches(BATCH_SIZE)
      specification = specification.from(event_id) if event_id
      specification.result
    end
  end
end
