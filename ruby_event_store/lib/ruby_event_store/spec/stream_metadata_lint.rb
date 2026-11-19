# frozen_string_literal: true

# Contract of a repository with native support for stream metadata, and of
# StreamMetadataAwareRepository on top of it.
#
# Use it next to the "event repository" lint, which stays unchanged:
#
#   it_behaves_like "stream metadata", mk_repository, helper
#
# mk_repository returns a new, empty native repository (not decorated).
# helper responds, besides what the "event repository" lint needs, to:
#
#   with_transaction { ... } - runs the block in one transaction of the repository's
#                              storage; a repository without transactions just yields
#
# == Native tier
#
# StreamMetadataAwareRepository calls only these methods, besides the ordinary repository
# interface. Visible / hidden: a hidden entry is a link of an event to a stream that reads
# of the stream skip; the event itself stays, the global stream is never filtered.
#
#   supports_native_truncation? => true
#     Asked once, by the decorator's constructor.
#
#   last_stream_version_and_tombstone(stream) => [Integer | nil, true | false]
#     In one read: the highest position in the stream, hidden entries and the tombstone
#     sentinel included (nil when the stream is empty or holds only entries without a
#     position), and whether the stream is tombstoned. The decorator turns an :auto
#     append into an Integer one with it, so an :auto append costs no extra read.
#
#   stream_metadata(stream) => StreamMetadata
#     The materialised metadata of the stream; StreamMetadata.none when it has none.
#
#   append_stream_metadata(record, stream, expected_version) => self
#     record is one of StreamMetadataEvents (event_type is the class name, data as
#     documented there). In one transaction:
#       1. raises WrongExpectedEventVersion unless the highest position of stream equals
#          an Integer expected_version, or stream is empty for :none; :auto and :any pass;
#       2. appends record to StreamMetadata.meta_stream(stream);
#       3. applies record to the materialised metadata of stream:
#          StreamMetadataChanged - sets max_count and max_age (nil clears)
#          StreamTruncated       - truncate_before and the hide boundary move up to the entries
#                                  at positions below "before_position", never back
#          StreamSoftDeleted     - soft_deleted_at = record.timestamp; the hide boundary moves up
#                                  to every entry the stream holds now; truncate_before moves up
#                                  to the highest position + 1 (stays when there is no position)
#          StreamTombstoned      - tombstoned_at = record.timestamp, and record is linked into
#                                  stream as a hidden sentinel at the highest position + 1
#                                  (0 for an empty stream, no position when the stream has
#                                  entries without one); the sentinel takes the position a
#                                  racing append would take, so one of them fails
#          StreamRestored        - clears soft_deleted_at, truncate_before and the hide boundary;
#                                  tombstoned_at and the retention settings stay
#          StreamScavenged       - nothing
#     Either all of it happens or nothing does. Marking entries hidden is not part of it.
#
#   mark_truncated(stream, batch_size) => Integer
#     Hides at most batch_size visible entries at or below the hide boundary, oldest
#     first, in one transaction. Returns how many it hid; 0 when none is left.
#     Repeating it after an interruption finishes the job.
#
#   unmark_truncated(stream, batch_size) => Integer
#     Shows again at most batch_size hidden entries above the hide boundary (every hidden
#     entry when there is no boundary), newest first, in one transaction. Never the
#     tombstone sentinel. Returns how many it showed; 0 when none is left.
#
# The hide boundary identifies entries (in SQL by the row id, e.g. truncated_upto_id), never
# a position: after delete_stream an :auto append starts again at position 0, and those
# entries must stay visible however often mark_truncated runs. truncate_before is only
# the public value recorded in the metadata.
#
# Reads of a native repository leave hidden entries out before any other part of the
# specification applies (limit, batches, first / last, from / to, count, time order).
# position_in_stream, event_in_stream? and streams_of treat a hidden entry as absent.
# last_stream_version and expected_version still count it, so positions never repeat.

require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  # @private
  StreamMetadataLintEvent = Class.new(RubyEventStore::Event)

  ::RSpec.shared_examples "stream metadata" do |mk_repository, helper|
    let(:repository) { mk_repository.call }
    let(:stream) { Stream.new(SecureRandom.uuid) }
    let(:other_stream) { Stream.new(SecureRandom.uuid) }
    let(:global_stream) { Stream.new(GLOBAL_STREAM) }
    let(:time) { Time.utc(2026, 11, 18, 12, 0, 0) }

    def append(repository, stream, count, expected_version = ExpectedVersion.auto)
      records = Array.new(count) { SRecord.new }
      repository.append_to_stream(records, stream, expected_version)
      records.map(&:event_id)
    end

    def read(repository, stream, &block)
      specification = Specification.new(nil).stream(stream.name)
      specification = block.call(specification) if block
      repository.read(specification.result).to_a
    end

    def read_ids(repository, stream, &block)
      read(repository, stream, &block).map(&:event_id)
    end

    def metadata_record(event_class, stream, timestamp: time, **data)
      Record.new(
        event_id: SecureRandom.uuid,
        event_type: event_class.name,
        data: { "stream" => stream.name }.merge(data.transform_keys(&:to_s)),
        metadata: {},
        timestamp: timestamp,
        valid_at: timestamp,
      )
    end

    def write(repository, event_class, stream, expected_version = ExpectedVersion.any, **data)
      record = metadata_record(event_class, stream, **data)
      repository.append_stream_metadata(record, stream, expected_version)
      record
    end

    def mark_all(repository, stream)
      nil until repository.mark_truncated(stream, 100).zero?
    end

    def soft_delete(repository, stream)
      write(repository, StreamMetadataEvents::StreamSoftDeleted, stream)
      mark_all(repository, stream)
    end

    def truncate(repository, stream, before_position)
      write(repository, StreamMetadataEvents::StreamTruncated, stream, before_position: before_position)
      mark_all(repository, stream)
    end

    describe "native tier" do
      specify "supports native truncation" do
        expect(repository.supports_native_truncation?).to be(true)
      end

      specify "has no metadata for a new stream" do
        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none)
      end

      specify "returns no last position and no tombstone for a new stream" do
        expect(repository.last_stream_version_and_tombstone(stream)).to eq([nil, false])
      end

      specify "returns last position and no tombstone for a stream with events" do
        append(repository, stream, 3)

        expect(repository.last_stream_version_and_tombstone(stream)).to eq([2, false])
      end

      specify "returns no last position for a stream with entries without position" do
        append(repository, stream, 2, ExpectedVersion.any)

        expect(repository.last_stream_version_and_tombstone(stream)).to eq([nil, false])
      end

      specify "returns last position of another stream unaffected" do
        append(repository, stream, 3)
        append(repository, other_stream, 1)

        expect(repository.last_stream_version_and_tombstone(other_stream)).to eq([0, false])
      end

      specify "appends a metadata record to the meta stream" do
        record = write(repository, StreamMetadataEvents::StreamMetadataChanged, stream, max_count: 10, max_age: nil)
        second = write(repository, StreamMetadataEvents::StreamMetadataChanged, stream, max_count: 5, max_age: nil)

        expect(read(repository, StreamMetadata.meta_stream(stream))).to eq([record, second])
        expect(repository.position_in_stream(second.event_id, StreamMetadata.meta_stream(stream))).to eq(1)
        expect(read_ids(repository, global_stream)).to eq([record.event_id, second.event_id])
        expect(read(repository, stream)).to be_empty
      end

      specify "returns self from append of a metadata record" do
        record = metadata_record(StreamMetadataEvents::StreamTombstoned, stream)

        expect(repository.append_stream_metadata(record, stream, ExpectedVersion.any)).to be(repository)
      end

      specify "refuses a metadata record with an id already stored" do
        event_ids = append(repository, stream, 1)
        record = metadata_record(StreamMetadataEvents::StreamTombstoned, stream).with(event_id: event_ids.first)

        expect { repository.append_stream_metadata(record, stream, ExpectedVersion.any) }.to raise_error(
          EventDuplicatedInStream,
        )
        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none)
        expect(repository.last_stream_version_and_tombstone(stream)).to eq([0, false])
        expect(read(repository, StreamMetadata.meta_stream(stream))).to be_empty
      end

      specify "checks expected version of the stream, not of the meta stream" do
        write(repository, StreamMetadataEvents::StreamMetadataChanged, stream, ExpectedVersion.none, max_count: 1, max_age: nil)
        append(repository, stream, 2)

        expect do
          write(repository, StreamMetadataEvents::StreamMetadataChanged, stream, ExpectedVersion.new(1), max_count: 2, max_age: nil)
          write(repository, StreamMetadataEvents::StreamMetadataChanged, stream, ExpectedVersion.auto, max_count: 3, max_age: nil)
        end.not_to raise_error
        expect(repository.stream_metadata(stream).max_count).to eq(3)
      end

      specify "changes nothing when expected version does not match" do
        append(repository, stream, 2)

        [ExpectedVersion.new(0), ExpectedVersion.new(2), ExpectedVersion.none].each do |expected_version|
          expect do
            write(repository, StreamMetadataEvents::StreamSoftDeleted, stream, expected_version)
          end.to raise_error(WrongExpectedEventVersion)
          expect do
            write(repository, StreamMetadataEvents::StreamTombstoned, stream, expected_version)
          end.to raise_error(WrongExpectedEventVersion)
        end
        mark_all(repository, stream)

        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none)
        expect(read(repository, StreamMetadata.meta_stream(stream))).to be_empty
        expect(read(repository, stream).size).to eq(2)
        expect(repository.last_stream_version_and_tombstone(stream)).to eq([1, false])
      end

      specify "sets and clears retention" do
        write(repository, StreamMetadataEvents::StreamMetadataChanged, stream, max_count: 10, max_age: 3600)
        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none.with(max_count: 10, max_age: 3600))

        write(repository, StreamMetadataEvents::StreamMetadataChanged, stream, max_count: nil, max_age: 60)
        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none.with(max_age: 60))
        expect(repository.stream_metadata(other_stream)).to eq(StreamMetadata.none)
      end

      specify "truncates below a position" do
        event_ids = append(repository, stream, 5)

        truncate(repository, stream, 3)

        expect(read_ids(repository, stream)).to eq(event_ids.drop(3))
        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none.with(truncate_before: 3))
      end

      specify "never moves truncation boundary back" do
        event_ids = append(repository, stream, 5)

        truncate(repository, stream, 3)
        truncate(repository, stream, 1)

        expect(read_ids(repository, stream)).to eq(event_ids.drop(3))
        expect(repository.stream_metadata(stream).truncate_before).to eq(3)
        expect(repository.unmark_truncated(stream, 10)).to eq(0)
      end

      specify "moves truncation boundary up" do
        event_ids = append(repository, stream, 5)

        truncate(repository, stream, 1)
        truncate(repository, stream, 3)

        expect(read_ids(repository, stream)).to eq(event_ids.drop(3))
        expect(repository.stream_metadata(stream).truncate_before).to eq(3)
      end

      specify "truncation hides nothing in a stream with entries without position" do
        event_ids = append(repository, stream, 2, ExpectedVersion.any)

        truncate(repository, stream, 5)

        expect(read_ids(repository, stream)).to eq(event_ids)
      end

      specify "keeps entries appended after delete_stream visible" do
        append(repository, stream, 2)
        soft_delete(repository, stream)
        repository.delete_stream(stream)

        event_ids = append(repository, stream, 2, ExpectedVersion.any)
        mark_all(repository, stream)

        expect(read_ids(repository, stream)).to eq(event_ids)
      end

      specify "keeps entries appended with :auto after soft delete and delete_stream visible" do
        append(repository, stream, 3)
        soft_delete(repository, stream)
        repository.delete_stream(stream)

        event_ids = append(repository, stream, 3, ExpectedVersion.auto)
        mark_all(repository, stream)

        expect(read_ids(repository, stream)).to eq(event_ids)
        expect(repository.position_in_stream(event_ids.first, stream)).to eq(0)
      end

      specify "keeps entries appended with :auto after truncate and delete_stream visible" do
        append(repository, stream, 4)
        truncate(repository, stream, 3)
        repository.delete_stream(stream)

        event_ids = append(repository, stream, 4, ExpectedVersion.auto)
        mark_all(repository, stream)

        expect(read_ids(repository, stream)).to eq(event_ids)
      end

      specify "keeps entries visible until they are marked" do
        event_ids = append(repository, stream, 3)

        write(repository, StreamMetadataEvents::StreamTruncated, stream, before_position: 2)

        expect(read_ids(repository, stream)).to eq(event_ids)
      end

      specify "marks in batches, oldest first" do
        event_ids = append(repository, stream, 5)
        write(repository, StreamMetadataEvents::StreamTruncated, stream, before_position: 4)

        expect(repository.mark_truncated(stream, 3)).to eq(3)
        expect(read_ids(repository, stream)).to eq(event_ids.drop(3))
        expect(repository.mark_truncated(stream, 3)).to eq(1)
        expect(read_ids(repository, stream)).to eq(event_ids.drop(4))
        expect(repository.mark_truncated(stream, 3)).to eq(0)
        expect(read_ids(repository, stream)).to eq(event_ids.drop(4))
      end

      specify "marks nothing without a boundary" do
        append(repository, stream, 2)
        write(repository, StreamMetadataEvents::StreamMetadataChanged, stream, max_count: 1, max_age: nil)

        expect(repository.mark_truncated(stream, 10)).to eq(0)
        expect(read(repository, stream).size).to eq(2)
      end

      specify "marks only the truncated stream" do
        append(repository, stream, 2)
        other_ids = append(repository, other_stream, 2)

        truncate(repository, stream, 2)

        expect(read(repository, stream)).to be_empty
        expect(read_ids(repository, other_stream)).to eq(other_ids)
        expect(repository.mark_truncated(other_stream, 10)).to eq(0)
      end

      specify "soft deletes every entry present at the time of writing" do
        append(repository, stream, 3)

        record = write(repository, StreamMetadataEvents::StreamSoftDeleted, stream, ExpectedVersion.new(2))
        later_ids = append(repository, stream, 1)
        mark_all(repository, stream)

        expect(read_ids(repository, stream)).to eq(later_ids)
        expect(repository.stream_metadata(stream)).to eq(
          StreamMetadata.none.with(truncate_before: 3, soft_deleted_at: record.timestamp),
        )
        expect(repository.last_stream_version_and_tombstone(stream)).to eq([3, false])
      end

      specify "soft deletes an empty stream" do
        record = write(repository, StreamMetadataEvents::StreamSoftDeleted, stream, ExpectedVersion.none)
        mark_all(repository, stream)
        event_ids = append(repository, stream, 1)

        expect(read_ids(repository, stream)).to eq(event_ids)
        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none.with(soft_deleted_at: record.timestamp))
      end

      specify "soft deletes a stream with entries without position" do
        append(repository, stream, 2, ExpectedVersion.any)

        record = write(repository, StreamMetadataEvents::StreamSoftDeleted, stream)
        mark_all(repository, stream)

        expect(read(repository, stream)).to be_empty
        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none.with(soft_deleted_at: record.timestamp))
      end

      specify "soft delete keeps a higher truncation boundary" do
        append(repository, stream, 3)
        truncate(repository, stream, 2)
        write(repository, StreamMetadataEvents::StreamRestored, stream)

        write(repository, StreamMetadataEvents::StreamTruncated, stream, before_position: 10)
        write(repository, StreamMetadataEvents::StreamSoftDeleted, stream)

        expect(repository.stream_metadata(stream).truncate_before).to eq(10)
      end

      specify "tombstones with a hidden sentinel at the next position" do
        event_ids = append(repository, stream, 2)

        record = write(repository, StreamMetadataEvents::StreamTombstoned, stream, ExpectedVersion.new(1))

        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none.with(tombstoned_at: record.timestamp))
        expect(repository.last_stream_version_and_tombstone(stream)).to eq([2, true])
        expect(read_ids(repository, stream)).to eq(event_ids)
        expect(read_ids(repository, StreamMetadata.meta_stream(stream))).to eq([record.event_id])
        expect(repository.streams_of(record.event_id)).to eq([StreamMetadata.meta_stream(stream)])
        expect(repository.event_in_stream?(record.event_id, stream)).to be(false)
        expect(repository.last_stream_version_and_tombstone(other_stream)).to eq([nil, false])
      end

      specify "tombstones an empty stream with a sentinel at position 0" do
        write(repository, StreamMetadataEvents::StreamTombstoned, stream, ExpectedVersion.none)

        expect(repository.last_stream_version_and_tombstone(stream)).to eq([0, true])
        expect(read(repository, stream)).to be_empty
      end

      specify "tombstones a stream with entries without position with a sentinel without position" do
        event_ids = append(repository, stream, 2, ExpectedVersion.any)

        write(repository, StreamMetadataEvents::StreamTombstoned, stream)

        expect(repository.last_stream_version_and_tombstone(stream)).to eq([nil, true])
        expect(read_ids(repository, stream)).to eq(event_ids)
      end

      specify "makes a racing append with expected version fail on the sentinel position" do
        append(repository, stream, 2)
        write(repository, StreamMetadataEvents::StreamTombstoned, stream)

        expect { append(repository, stream, 1, ExpectedVersion.new(1)) }.to raise_error(WrongExpectedEventVersion)
        expect(read(repository, stream).size).to eq(2)
      end

      specify "makes a racing append to an empty stream fail on the sentinel position" do
        write(repository, StreamMetadataEvents::StreamTombstoned, stream)

        expect { append(repository, stream, 1, ExpectedVersion.none) }.to raise_error(WrongExpectedEventVersion)
      end

      specify "refuses to link the tombstone event into its stream" do
        append(repository, stream, 1)
        record = write(repository, StreamMetadataEvents::StreamTombstoned, stream)

        expect { repository.link_to_stream([record.event_id], stream, ExpectedVersion.new(1)) }.to raise_error(
          EventDuplicatedInStream,
        )
      end

      specify "keeps history of a tombstoned stream readable" do
        event_ids = append(repository, stream, 3)

        write(repository, StreamMetadataEvents::StreamTombstoned, stream)

        expect(read_ids(repository, stream)).to eq(event_ids)
        expect(repository.count(Specification.new(nil).stream(stream.name).result)).to eq(3)
        expect(repository.last_stream_event(stream).event_id).to eq(event_ids.last)
        expect(repository.position_in_stream(event_ids.last, stream)).to eq(2)
        expect(repository.event_in_stream?(event_ids.first, stream)).to be(true)
        expect(repository.streams_of(event_ids.first)).to eq([stream])
      end

      specify "restores hidden entries in batches, newest first" do
        event_ids = append(repository, stream, 5)
        soft_delete(repository, stream)

        write(repository, StreamMetadataEvents::StreamRestored, stream)

        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none)
        expect(repository.unmark_truncated(stream, 3)).to eq(3)
        expect(read_ids(repository, stream)).to eq(event_ids.drop(2))
        expect(repository.unmark_truncated(stream, 3)).to eq(2)
        expect(read_ids(repository, stream)).to eq(event_ids)
        expect(repository.unmark_truncated(stream, 3)).to eq(0)
      end

      specify "unmarks only above the boundary" do
        event_ids = append(repository, stream, 4)
        soft_delete(repository, stream)
        write(repository, StreamMetadataEvents::StreamRestored, stream)
        write(repository, StreamMetadataEvents::StreamTruncated, stream, before_position: 2)

        expect(repository.unmark_truncated(stream, 10)).to eq(2)
        expect(read_ids(repository, stream)).to eq(event_ids.drop(2))
        expect(repository.mark_truncated(stream, 10)).to eq(0)
      end

      specify "unmarks only the restored stream" do
        append(repository, stream, 2)
        append(repository, other_stream, 2)
        soft_delete(repository, stream)
        soft_delete(repository, other_stream)

        write(repository, StreamMetadataEvents::StreamRestored, stream)

        expect(repository.unmark_truncated(stream, 10)).to eq(2)
        expect(repository.unmark_truncated(other_stream, 10)).to eq(0)
        expect(read(repository, other_stream)).to be_empty
      end

      specify "never restores the tombstone sentinel" do
        event_ids = append(repository, stream, 2)
        write(repository, StreamMetadataEvents::StreamTombstoned, stream)
        soft_delete(repository, stream)

        write(repository, StreamMetadataEvents::StreamRestored, stream)

        expect(repository.unmark_truncated(stream, 10)).to eq(2)
        expect(read_ids(repository, stream)).to eq(event_ids)
        expect(repository.last_stream_version_and_tombstone(stream)).to eq([2, true])
      end

      specify "keeps tombstone and retention on restore" do
        append(repository, stream, 1)
        write(repository, StreamMetadataEvents::StreamMetadataChanged, stream, max_count: 10, max_age: 60)
        tombstone = write(repository, StreamMetadataEvents::StreamTombstoned, stream)
        soft_delete(repository, stream)

        write(repository, StreamMetadataEvents::StreamRestored, stream)

        expect(repository.stream_metadata(stream)).to eq(
          StreamMetadata.none.with(max_count: 10, max_age: 60, tombstoned_at: tombstone.timestamp),
        )
      end

      specify "changes no metadata on scavenged" do
        append(repository, stream, 1)

        write(
          repository,
          StreamMetadataEvents::StreamScavenged,
          stream,
          policy: "links_only",
          removed_links: 0,
          removed_events: 0,
        )

        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none)
        expect(read(repository, StreamMetadata.meta_stream(stream)).size).to eq(1)
      end

      specify "leaves hidden entries out before limit" do
        event_ids = append(repository, stream, 5)
        truncate(repository, stream, 2)

        expect(read_ids(repository, stream) { |spec| spec.limit(2) }).to eq(event_ids.drop(2).take(2))
        expect(read_ids(repository, stream) { |spec| spec.backward.limit(4) }).to eq(event_ids.drop(2).reverse)
      end

      specify "leaves hidden entries out of batched reads" do
        event_ids = append(repository, stream, 5)
        truncate(repository, stream, 2)

        batches = repository.read(Specification.new(nil).stream(stream.name).in_batches(2).result).to_a

        expect(batches.map { |batch| batch.map(&:event_id) }).to eq(event_ids.drop(2).each_slice(2).to_a)
      end

      specify "leaves hidden entries out of first and last" do
        event_ids = append(repository, stream, 4)
        truncate(repository, stream, 2)
        soft_delete(repository, other_stream)

        expect(repository.read(Specification.new(nil).stream(stream.name).read_first.result).event_id).to eq(
          event_ids[2],
        )
        expect(repository.read(Specification.new(nil).stream(stream.name).read_last.result).event_id).to eq(
          event_ids[3],
        )
        soft_delete(repository, stream)
        expect(repository.read(Specification.new(nil).stream(stream.name).read_first.result)).to be_nil
        expect(repository.read(Specification.new(nil).stream(stream.name).read_last.result)).to be_nil
        expect(repository.last_stream_event(stream)).to be_nil
      end

      specify "leaves hidden entries out of count" do
        append(repository, stream, 4)
        truncate(repository, stream, 3)

        expect(repository.count(Specification.new(nil).stream(stream.name).result)).to eq(1)
      end

      specify "leaves hidden entries out of reads from and to an event" do
        event_ids = append(repository, stream, 5)
        truncate(repository, stream, 2)

        expect(read_ids(repository, stream) { |spec| spec.from(event_ids[2]) }).to eq(event_ids.drop(3))
        expect(read_ids(repository, stream) { |spec| spec.to(event_ids[4]) }).to eq(event_ids[2..3])
        expect(read_ids(repository, stream) { |spec| spec.backward.to(event_ids[2]) }).to eq(event_ids[3..4].reverse)
      end

      specify "leaves hidden entries out of time sorted reads" do
        records = [
          SRecord.new(timestamp: Time.utc(2026, 1, 3), valid_at: Time.utc(2026, 1, 1)),
          SRecord.new(timestamp: Time.utc(2026, 1, 1), valid_at: Time.utc(2026, 1, 3)),
          SRecord.new(timestamp: Time.utc(2026, 1, 2), valid_at: Time.utc(2026, 1, 2)),
        ]
        repository.append_to_stream(records, stream, ExpectedVersion.none)
        truncate(repository, stream, 1)

        expect(read_ids(repository, stream, &:as_at)).to eq([records[1], records[2]].map(&:event_id))
        expect(read_ids(repository, stream, &:as_of)).to eq([records[2], records[1]].map(&:event_id))
        expect(read_ids(repository, stream) { |spec| spec.older_than(Time.utc(2026, 1, 3)) }).to eq(
          [records[1], records[2]].map(&:event_id),
        )
      end

      specify "leaves hidden entries out of reads by type and id" do
        records = [SRecord.new(event_type: "A"), SRecord.new(event_type: "A"), SRecord.new(event_type: "B")]
        repository.append_to_stream(records, stream, ExpectedVersion.none)
        truncate(repository, stream, 1)

        expect(read_ids(repository, stream) { |spec| spec.of_type("A") }).to eq([records[1].event_id])
        expect(read_ids(repository, stream) { |spec| spec.with_id(records.map(&:event_id)) }).to eq(
          records.drop(1).map(&:event_id),
        )
      end

      specify "does not filter the global stream" do
        event_ids = append(repository, stream, 3)
        soft_delete(repository, stream)

        expect(read_ids(repository, global_stream)).to start_with(event_ids)
        expect(event_ids.all? { |event_id| repository.has_event?(event_id) }).to be(true)
      end

      specify "treats hidden entries as absent in position_in_stream" do
        event_ids = append(repository, stream, 3)
        truncate(repository, stream, 1)

        expect { repository.position_in_stream(event_ids[0], stream) }.to raise_error(EventNotFoundInStream)
        expect(repository.position_in_stream(event_ids[1], stream)).to eq(1)
      end

      specify "treats hidden entries as absent in event_in_stream?" do
        event_ids = append(repository, stream, 3)
        truncate(repository, stream, 1)

        expect(repository.event_in_stream?(event_ids[0], stream)).to be(false)
        expect(repository.event_in_stream?(event_ids[1], stream)).to be(true)
      end

      specify "treats hidden entries as absent in streams_of" do
        event_ids = append(repository, stream, 1)
        repository.link_to_stream(event_ids, other_stream, ExpectedVersion.none)

        soft_delete(repository, stream)

        expect(repository.streams_of(event_ids.first)).to eq([other_stream])
      end

      specify "refuses to link an event already hidden in the stream" do
        event_ids = append(repository, stream, 1)
        soft_delete(repository, stream)

        expect { repository.link_to_stream(event_ids, stream, ExpectedVersion.auto) }.to raise_error(
          EventDuplicatedInStream,
        )
      end

      specify "counts hidden entries in last stream version" do
        append(repository, stream, 3)
        soft_delete(repository, stream)

        expect { append(repository, stream, 1, ExpectedVersion.none) }.to raise_error(WrongExpectedEventVersion)
        expect { append(repository, stream, 1, ExpectedVersion.new(0)) }.to raise_error(WrongExpectedEventVersion)
        event_ids = append(repository, stream, 1, ExpectedVersion.new(2))
        append(repository, stream, 1, ExpectedVersion.auto)

        expect(repository.position_in_stream(event_ids.first, stream)).to eq(3)
        expect(repository.last_stream_version_and_tombstone(stream)).to eq([4, false])
      end
    end

    describe "with StreamMetadataAwareRepository" do
      let(:decorated) { StreamMetadataAwareRepository.new(repository) }
      let(:client) { Client.new(repository: decorated) }

      specify "reserves stream names starting with $ for append and link" do
        client.append(event = StreamMetadataLintEvent.new, stream_name: "some")

        expect { client.append(StreamMetadataLintEvent.new, stream_name: "$$some") }.to raise_error(ReservedInternalName)
        expect { client.link(event.event_id, stream_name: "$some") }.to raise_error(ReservedInternalName)
        expect { client.append(StreamMetadataLintEvent.new, stream_name: "some$") }.not_to raise_error
      end

      specify "refuses metadata of a reserved stream" do
        expect { client.set_stream_metadata("$$some", max_count: 1) }.to raise_error(ReservedInternalName)
        expect { client.soft_delete_stream("$some") }.to raise_error(ReservedInternalName)
        expect { client.stream_metadata("$some") }.to raise_error(ReservedInternalName)
      end

      specify "refuses append and link to a tombstoned stream with :auto" do
        client.append(event = StreamMetadataLintEvent.new, stream_name: "other")
        client.tombstone_stream("some")

        expect { client.append(StreamMetadataLintEvent.new, stream_name: "some", expected_version: :auto) }.to raise_error(
          StreamTombstoned,
        )
        expect { client.link(event.event_id, stream_name: "some", expected_version: :auto) }.to raise_error(
          StreamTombstoned,
        )
      end

      specify "refuses append and link to a tombstoned stream with other expected versions" do
        client.append(event = StreamMetadataLintEvent.new, stream_name: "other")
        client.append(StreamMetadataLintEvent.new, stream_name: "some")
        client.tombstone_stream("some")

        [:any, :none, 0].each do |expected_version|
          expect do
            client.append(StreamMetadataLintEvent.new, stream_name: "some", expected_version: expected_version)
          end.to raise_error(StreamTombstoned)
          expect do
            client.link(event.event_id, stream_name: "some", expected_version: expected_version)
          end.to raise_error(StreamTombstoned)
        end
      end

      specify "refuses a second tombstone" do
        client.tombstone_stream("some")

        expect { client.tombstone_stream("some") }.to raise_error(StreamTombstoned)
      end

      specify "allows truncate, soft delete, restore and retention after tombstone" do
        client.append([StreamMetadataLintEvent.new, second = StreamMetadataLintEvent.new], stream_name: "some", expected_version: :auto)
        client.tombstone_stream("some")

        client.truncate_stream("some", before: 1)
        expect(client.read.stream("some").to_a).to eq([second])
        client.soft_delete_stream("some")
        expect(client.read.stream("some").to_a).to be_empty
        client.restore_stream("some")
        expect(client.read.stream("some").count).to eq(2)
        client.set_stream_metadata("some", max_count: 1)
        expect(client.stream_metadata("some")).to have_attributes(max_count: 1, tombstoned?: true)
      end

      specify "allows append after soft delete and continues positions" do
        client.append([StreamMetadataLintEvent.new, StreamMetadataLintEvent.new], stream_name: "some", expected_version: :auto)
        client.soft_delete_stream("some", expected_version: 1)

        client.append(event = StreamMetadataLintEvent.new, stream_name: "some", expected_version: :auto)

        expect(client.read.stream("some").to_a).to eq([event])
        expect(client.position_in_stream(event.event_id, "some")).to eq(2)
        expect(client.stream_metadata("some")).to be_soft_deleted
      end

      specify "append + soft delete in one transaction marks every appended event" do
        helper.with_transaction do
          client.append([StreamMetadataLintEvent.new, StreamMetadataLintEvent.new, StreamMetadataLintEvent.new], stream_name: "some", expected_version: :auto)
          client.soft_delete_stream("some", expected_version: 2)
        end

        expect(client.read.stream("some").to_a).to be_empty
        expect(client.read.stream("some").count).to eq(0)
      end

      specify "restore makes soft deleted events visible again" do
        client.append(events = [StreamMetadataLintEvent.new, StreamMetadataLintEvent.new], stream_name: "some", expected_version: :auto)
        client.soft_delete_stream("some")

        restore = client.restore_stream("some")

        expect(client.read.stream("some").to_a).to eq(events)
        expect(restore).to eq(StreamMetadataAwareRepository::StreamRestore.new(restored: 2, missing: 0))
        expect(client.stream_metadata("some")).not_to be_deleted
      end

      specify "marks streams larger than a batch" do
        client = Client.new(repository: StreamMetadataAwareRepository.new(repository, batch_size: 2))
        client.append(events = Array.new(5) { StreamMetadataLintEvent.new }, stream_name: "some", expected_version: :auto)

        client.truncate_stream("some", before: 4)
        expect(client.read.stream("some").to_a).to eq(events.drop(4))
        client.soft_delete_stream("some")
        expect(client.read.stream("some").to_a).to be_empty
        expect(client.restore_stream("some").restored).to eq(5)
        expect(client.read.stream("some").to_a).to eq(events)
      end

      specify "reads metadata events from the meta stream" do
        client.append(StreamMetadataLintEvent.new, stream_name: "some")
        client.set_stream_metadata("some", max_count: 10, max_age: 60)
        client.soft_delete_stream("some")

        events = client.read.stream("$$some").to_a

        expect(events.map(&:class)).to eq(
          [StreamMetadataEvents::StreamMetadataChanged, StreamMetadataEvents::StreamSoftDeleted],
        )
        expect(events.map { |event| event.data.fetch("stream") }).to eq(%w[some some])
        expect(events.first.data).to include("max_count" => 10, "max_age" => 60)
      end
    end
  end
end
