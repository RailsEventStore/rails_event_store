# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe StreamMetadata do
    let(:time) { Time.utc(2026, 11, 18, 12, 0, 0) }

    specify "none has every attribute empty" do
      expect(StreamMetadata.none).to eq(
        StreamMetadata.new(max_count: nil, max_age: nil, truncate_before: nil, tombstoned_at: nil, soft_deleted_at: nil),
      )
    end

    specify "is frozen" do
      expect(StreamMetadata.none).to be_frozen
    end

    specify "meta stream" do
      expect(StreamMetadata.meta_stream(Stream.new("Order$1"))).to eq(Stream.new("$$Order$1"))
    end

    specify "empty" do
      expect(StreamMetadata.none).to be_empty
      expect(StreamMetadata.none.with(max_count: 1)).not_to be_empty
      expect(StreamMetadata.none.with(max_age: 1)).not_to be_empty
      expect(StreamMetadata.none.with(truncate_before: 0)).not_to be_empty
      expect(StreamMetadata.none.with(tombstoned_at: time)).not_to be_empty
      expect(StreamMetadata.none.with(soft_deleted_at: time)).not_to be_empty
    end

    specify "tombstoned" do
      expect(StreamMetadata.none).not_to be_tombstoned
      expect(StreamMetadata.none.with(soft_deleted_at: time)).not_to be_tombstoned
      expect(StreamMetadata.none.with(tombstoned_at: time)).to be_tombstoned
    end

    specify "soft deleted" do
      expect(StreamMetadata.none).not_to be_soft_deleted
      expect(StreamMetadata.none.with(tombstoned_at: time)).not_to be_soft_deleted
      expect(StreamMetadata.none.with(soft_deleted_at: time)).to be_soft_deleted
    end

    specify "deleted" do
      expect(StreamMetadata.none).not_to be_deleted
      expect(StreamMetadata.none.with(truncate_before: 3)).not_to be_deleted
      expect(StreamMetadata.none.with(tombstoned_at: time)).to be_deleted
      expect(StreamMetadata.none.with(soft_deleted_at: time)).to be_deleted
    end

    specify "retention" do
      expect(StreamMetadata.none).not_to be_retention
      expect(StreamMetadata.none.with(truncate_before: 3, soft_deleted_at: time)).not_to be_retention
      expect(StreamMetadata.none.with(max_count: 10)).to be_retention
      expect(StreamMetadata.none.with(max_age: 60)).to be_retention
    end
  end

  ::RSpec.describe StreamMetadataEvents do
    specify "are events named after the class" do
      [
        StreamMetadataEvents::StreamMetadataChanged,
        StreamMetadataEvents::StreamTruncated,
        StreamMetadataEvents::StreamSoftDeleted,
        StreamMetadataEvents::StreamTombstoned,
        StreamMetadataEvents::StreamRestored,
        StreamMetadataEvents::StreamScavenged,
      ].each do |klass|
        expect(klass.superclass).to be(Event)
        expect(klass.new.event_type).to eq(klass.name)
      end
    end

    specify "tombstoned event is not the tombstoned error" do
      expect(StreamMetadataEvents::StreamTombstoned).not_to be(StreamTombstoned)
      expect(StreamTombstoned.superclass).to be(Error)
    end
  end
end
