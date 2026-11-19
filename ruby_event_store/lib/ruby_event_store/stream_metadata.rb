# frozen_string_literal: true

module RubyEventStore
  # Metadata of a stream: retention, truncation, soft delete and tombstone.
  #
  # max_count       - number of entries the stream keeps (enforced by the scavenger)
  # max_age         - seconds an entry stays in the stream after it was linked (enforced by the scavenger)
  # truncate_before - position below which entries are hidden from reads of the stream
  # tombstoned_at   - time the stream was closed for writes, nil when it is open
  # soft_deleted_at - time the stream was soft deleted, nil when it is not
  class StreamMetadata < Data.define(:max_count, :max_age, :truncate_before, :tombstoned_at, :soft_deleted_at)
    def self.none
      new(max_count: nil, max_age: nil, truncate_before: nil, tombstoned_at: nil, soft_deleted_at: nil)
    end

    # Name of the stream which holds the metadata events of the given stream.
    #
    # @param stream [Stream]
    # @return [Stream]
    def self.meta_stream(stream)
      Stream.new("$$#{stream.name}")
    end

    def tombstoned?
      !tombstoned_at.nil?
    end

    def soft_deleted?
      !soft_deleted_at.nil?
    end

    def deleted?
      tombstoned? || soft_deleted?
    end

    def retention?
      !max_count.nil? || !max_age.nil?
    end

    def empty?
      to_h.values.all?(&:nil?)
    end
  end
end
