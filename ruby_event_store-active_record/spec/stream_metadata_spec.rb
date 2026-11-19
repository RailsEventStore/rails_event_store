# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store"
require "ruby_event_store/spec/event_repository_lint"
require "ruby_event_store/spec/stream_metadata_lint"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe EventRepository do
      helper = NativeTruncationSpecHelper.new

      mk_serializer = -> do
        case ENV["DATA_TYPE"]
        when /json/
          JSON
        else
          RubyEventStore::Serializers::YAML
        end
      end

      mk_repository = -> { EventRepository.new(serializer: mk_serializer.call) }

      around { |example| helper.run_lifecycle { example.run } }

      it_behaves_like "stream metadata", mk_repository, helper

      context "with native truncation migrations" do
        it_behaves_like "event repository", mk_repository, helper
      end

      let(:repository) { mk_repository.call }
      let(:specification) { Specification.new(SpecificationReader.new(repository, Mappers::Default.new)) }
      let(:stream) { Stream.new("Order$1") }
      let(:meta_stream) { Stream.new("$$Order$1") }

      def meta(type, stream = self.stream, **data)
        SRecord.new(
          event_type: "RubyEventStore::StreamMetadataEvents::#{type}",
          data: { "stream" => stream.name }.merge(data.transform_keys(&:to_s)),
        )
      end

      def append(count, stream = self.stream, expected_version = ExpectedVersion.auto)
        records = Array.new(count) { SRecord.new }
        repository.append_to_stream(records, stream, expected_version)
        records.map(&:event_id)
      end

      def write_metadata(record, stream = self.stream, expected_version = ExpectedVersion.any)
        repository.append_stream_metadata(record, stream, expected_version)
      end

      def read(spec = specification.stream(stream.name))
        repository.read(spec.result).map(&:event_id)
      end

      def mark_all(stream = self.stream)
        repository.mark_truncated(stream, 1_000)
      end

      def links(stream = self.stream)
        EventInStream.where(stream: stream.name).order(:id).pluck(:event_id, :position, :truncated_at)
      end

      describe "supports_native_truncation?" do
        specify "with column, partial index and metadata table" do
          expect(repository.supports_native_truncation?).to be(true)
        end

        specify "without streams metadata table" do
          helper.drop_streams_metadata

          expect(repository.supports_native_truncation?).to be(false)
        end

        specify "without truncated_at migration" do
          helper.remove_truncated_at
          helper.reset_column_information

          expect(repository.supports_native_truncation?).to be(false)
        end

        specify "with truncated_at column alone where database has no partial indexes" do
          ::ActiveRecord::Base.connection.remove_index(
            :event_store_events_in_streams,
            name: "index_event_store_events_in_streams_on_stream_and_id_visible",
            if_exists: true,
          )
          allow_any_instance_of(::ActiveRecord::Base.connection.class).to receive(:supports_partial_index?).and_return(
            false,
          )

          expect(repository.supports_native_truncation?).to be(true)
        end

        specify "without truncated_at column where database has no partial indexes" do
          helper.remove_truncated_at
          helper.reset_column_information
          allow_any_instance_of(::ActiveRecord::Base.connection.class).to receive(:supports_partial_index?).and_return(
            false,
          )

          expect(repository.supports_native_truncation?).to be(false)
        end

        specify "without partial index where database has partial indexes" do
          ::ActiveRecord::Base.connection.remove_index(
            :event_store_events_in_streams,
            name: "index_event_store_events_in_streams_on_stream_and_id_visible",
            if_exists: true,
          )
          allow_any_instance_of(::ActiveRecord::Base.connection.class).to receive(:supports_partial_index?).and_return(
            true,
          )

          expect(repository.supports_native_truncation?).to be(false)
        end

        specify "is checked once" do
          repository.supports_native_truncation?
          helper.remove_truncated_at
          helper.reset_column_information

          expect(repository.supports_native_truncation?).to be(true)
        end
      end

      describe "stream_metadata" do
        specify "none for a new stream" do
          expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none)
        end

        specify "materialised from metadata records" do
          write_metadata(meta(:StreamMetadataChanged, max_count: 10, max_age: 3600))
          write_metadata(meta(:StreamTruncated, before_position: 2))
          write_metadata(tombstone = meta(:StreamTombstoned))
          write_metadata(soft_delete = meta(:StreamSoftDeleted))

          expect(repository.stream_metadata(stream)).to eq(
            StreamMetadata.new(
              max_count: 10,
              max_age: 3600,
              truncate_before: 2,
              tombstoned_at: tombstone.timestamp,
              soft_deleted_at: soft_delete.timestamp,
            ),
          )
        end

        specify "of one stream only" do
          write_metadata(meta(:StreamMetadataChanged, Stream.new("other"), max_count: 10, max_age: nil), Stream.new("other"))

          expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none)
        end
      end

      describe "last_stream_version_and_tombstone" do
        specify "new stream" do
          expect(repository.last_stream_version_and_tombstone(stream)).to eq([nil, false])
        end

        specify "stream with events" do
          append(2)

          expect(repository.last_stream_version_and_tombstone(stream)).to eq([1, false])
        end

        specify "stream with entries without position" do
          append(2, stream, ExpectedVersion.any)

          expect(repository.last_stream_version_and_tombstone(stream)).to eq([nil, false])
        end

        specify "stream with metadata but no tombstone" do
          append(1)
          write_metadata(meta(:StreamMetadataChanged, max_count: 1, max_age: nil))

          expect(repository.last_stream_version_and_tombstone(stream)).to eq([0, false])
        end

        specify "counts hidden entries" do
          append(3)
          write_metadata(meta(:StreamSoftDeleted))
          mark_all

          expect(repository.last_stream_version_and_tombstone(stream)).to eq([2, false])
        end

        specify "tombstoned stream reports position of the sentinel" do
          append(2)
          write_metadata(meta(:StreamTombstoned))

          expect(repository.last_stream_version_and_tombstone(stream)).to eq([2, true])
        end

        specify "tombstone of other stream" do
          append(1)
          append(1, Stream.new("other"))
          write_metadata(meta(:StreamTombstoned, Stream.new("other")), Stream.new("other"))

          expect(repository.last_stream_version_and_tombstone(stream)).to eq([0, false])
        end

        specify "is one query" do
          append(1)
          write_metadata(meta(:StreamTombstoned))

          expect { repository.last_stream_version_and_tombstone(stream) }.to match_query_count(1)
        end
      end

      describe "append_stream_metadata" do
        specify "appends the record to the meta stream" do
          write_metadata(record = meta(:StreamMetadataChanged, max_count: 1, max_age: nil))

          expect(read(specification.stream(meta_stream.name))).to eq([record.event_id])
          expect(repository.position_in_stream(record.event_id, meta_stream)).to eq(0)
        end

        specify "returns self" do
          expect(write_metadata(meta(:StreamScavenged, policy: "links_only", removed_links: 0, removed_events: 0))).to be(
            repository,
          )
        end

        specify "checks expected version of the stream, not of the meta stream" do
          append(2)
          write_metadata(meta(:StreamMetadataChanged, max_count: 1, max_age: nil), stream, ExpectedVersion.new(1))
          write_metadata(meta(:StreamMetadataChanged, max_count: 2, max_age: nil), stream, ExpectedVersion.new(1))
          write_metadata(meta(:StreamMetadataChanged, max_count: 3, max_age: nil), stream, ExpectedVersion.auto)
          write_metadata(meta(:StreamMetadataChanged, max_count: 4, max_age: nil), stream, ExpectedVersion.any)

          expect(repository.stream_metadata(stream).max_count).to eq(4)
        end

        specify "with expected version none on an empty stream" do
          write_metadata(meta(:StreamMetadataChanged, max_count: 1, max_age: nil), stream, ExpectedVersion.none)

          expect(repository.stream_metadata(stream).max_count).to eq(1)
        end

        specify "changes nothing when expected version does not match" do
          append(2)

          [ExpectedVersion.new(0), ExpectedVersion.new(2), ExpectedVersion.none].each do |expected_version|
            expect do
              write_metadata(meta(:StreamTombstoned), stream, expected_version)
            end.to raise_error(WrongExpectedEventVersion)
          end
          expect(read(specification.stream(meta_stream.name))).to be_empty
          expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none)
          expect(links.size).to eq(2)
        end

        specify "expected version none on stream with entries without position" do
          append(1, stream, ExpectedVersion.any)

          expect do
            write_metadata(meta(:StreamSoftDeleted), stream, ExpectedVersion.none)
          end.to raise_error(WrongExpectedEventVersion)
        end

        specify "integer expected version on stream with entries without position" do
          append(1, stream, ExpectedVersion.any)

          expect do
            write_metadata(meta(:StreamSoftDeleted), stream, ExpectedVersion.new(-1))
          end.to raise_error(WrongExpectedEventVersion)
        end

        specify "changes nothing when metadata of the stream is written concurrently" do
          allow(repository.send(:metadata_klass)).to receive(:insert_all!).and_raise(::ActiveRecord::RecordNotUnique)

          expect { write_metadata(meta(:StreamTombstoned)) }.to raise_error(WrongExpectedEventVersion)
          expect(read(specification.stream(meta_stream.name))).to be_empty
          expect(links).to be_empty
        end

        specify "same record twice" do
          write_metadata(record = meta(:StreamSoftDeleted))

          expect { write_metadata(record) }.to raise_error(EventDuplicatedInStream)
        end

        specify "sets and clears retention" do
          write_metadata(meta(:StreamMetadataChanged, max_count: 10, max_age: 60))
          expect(repository.stream_metadata(stream)).to have_attributes(max_count: 10, max_age: 60)

          write_metadata(meta(:StreamMetadataChanged, max_count: nil, max_age: 30))
          expect(repository.stream_metadata(stream)).to have_attributes(max_count: nil, max_age: 30)
        end

        specify "retention leaves truncation as it is" do
          write_metadata(meta(:StreamTruncated, before_position: 3))
          write_metadata(meta(:StreamMetadataChanged, max_count: 10, max_age: nil))

          expect(repository.stream_metadata(stream).truncate_before).to eq(3)
        end

        specify "scavenged changes no metadata" do
          write_metadata(meta(:StreamScavenged, policy: "links_only", removed_links: 1, removed_events: 0))

          expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none)
          expect(::ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM event_store_streams_metadata")).to eq(0)
        end
      end

      describe "truncate" do
        specify "below a position" do
          events = append(5)
          write_metadata(meta(:StreamTruncated, before_position: 2))
          mark_all

          expect(read).to eq(events.drop(2))
          expect(repository.stream_metadata(stream).truncate_before).to eq(2)
        end

        specify "never moves truncation boundary back" do
          events = append(5)
          write_metadata(meta(:StreamTruncated, before_position: 3))
          write_metadata(meta(:StreamTruncated, before_position: 1))
          mark_all

          expect(read).to eq(events.drop(3))
          expect(repository.stream_metadata(stream).truncate_before).to eq(3)
        end

        specify "keeps entries visible until marking" do
          events = append(3)
          write_metadata(meta(:StreamTruncated, before_position: 2))

          expect(read).to eq(events)
        end

        specify "marks in batches, oldest first" do
          events = append(5)
          write_metadata(meta(:StreamTruncated, before_position: 4))

          expect(repository.mark_truncated(stream, 3)).to eq(3)
          expect(read).to eq(events.drop(3))
          expect(repository.mark_truncated(stream, 3)).to eq(1)
          expect(read).to eq(events.drop(4))
        end

        specify "marks nothing above the boundary" do
          events = append(3)
          write_metadata(meta(:StreamTruncated, before_position: 1))

          expect(mark_all).to eq(1)
          expect(read).to eq(events.drop(1))
        end

        specify "marks nothing more once done" do
          append(3)
          write_metadata(meta(:StreamTruncated, before_position: 2))
          mark_all

          expect(mark_all).to eq(0)
        end

        specify "marks nothing without a boundary" do
          events = append(2)
          write_metadata(meta(:StreamMetadataChanged, max_count: 1, max_age: nil))

          expect(mark_all).to eq(0)
          expect(mark_all(Stream.new("unknown"))).to eq(0)
          expect(read).to eq(events)
        end

        specify "marks only the given stream" do
          other = append(2, Stream.new("other"))
          write_metadata(meta(:StreamTruncated, before_position: 5))
          write_metadata(meta(:StreamTruncated, Stream.new("other"), before_position: 5), Stream.new("other"))

          expect(mark_all).to eq(0)
          expect(read(specification.stream("other"))).to eq(other)
        end

        specify "keeps entries appended with :auto after delete_stream visible" do
          append(3)
          write_metadata(meta(:StreamTruncated, before_position: 2))
          mark_all
          repository.delete_stream(stream)
          later = append(2)

          expect(mark_all).to eq(0)
          expect(read).to eq(later)
        end

        specify "hides no entries without position" do
          events = append(2, stream, ExpectedVersion.any)
          write_metadata(meta(:StreamTruncated, before_position: 5))

          expect(mark_all).to eq(0)
          expect(read).to eq(events)
        end

        specify "records time of marking" do
          append(1)
          write_metadata(meta(:StreamTruncated, before_position: 1))
          mark_all

          expect(links.last.last).to be_within(60).of(Time.now.utc)
        end
      end

      describe "soft delete" do
        specify "hides every entry present at the time of writing" do
          append(3)
          write_metadata(meta(:StreamSoftDeleted))
          mark_all

          expect(read).to be_empty
          expect(repository.stream_metadata(stream).truncate_before).to eq(3)
        end

        specify "keeps entries appended after soft delete visible" do
          append(3)
          write_metadata(meta(:StreamSoftDeleted))
          later = append(2)
          mark_all

          expect(read).to eq(later)
          expect(repository.position_in_stream(later.first, stream)).to eq(3)
        end

        specify "stream with entries without position" do
          append(2, stream, ExpectedVersion.any)
          write_metadata(meta(:StreamSoftDeleted))
          later = append(1, stream, ExpectedVersion.any)
          mark_all

          expect(read).to eq(later)
          expect(repository.stream_metadata(stream).truncate_before).to be_nil
        end

        specify "of an empty stream" do
          write_metadata(meta(:StreamSoftDeleted))
          later = append(1)

          expect(mark_all).to eq(0)
          expect(read).to eq(later)
        end

        specify "never moves the boundary back" do
          append(3)
          write_metadata(meta(:StreamTruncated, before_position: 10))
          write_metadata(meta(:StreamSoftDeleted))

          expect(repository.stream_metadata(stream).truncate_before).to eq(10)
        end

        specify "again moves the boundary up" do
          append(1, stream, ExpectedVersion.any)
          write_metadata(meta(:StreamSoftDeleted))
          later = append(1, stream, ExpectedVersion.any)
          write_metadata(meta(:StreamSoftDeleted))
          mark_all

          expect(read).to be_empty
          expect(links.map(&:first)).to include(*later)
        end

        specify "of the stream only" do
          other = append(2, Stream.new("other"))
          append(1)
          write_metadata(meta(:StreamSoftDeleted))
          mark_all

          expect(read(specification.stream("other"))).to eq(other)
        end
      end

      describe "tombstone" do
        specify "links a hidden sentinel at the next position" do
          events = append(2)
          write_metadata(record = meta(:StreamTombstoned))

          event_id, position, truncated_at = links.last
          expect([event_id, position]).to eq([record.event_id, 2])
          expect(truncated_at).to be_within(60).of(Time.now.utc)
          expect(read).to eq(events)
          expect(repository.stream_metadata(stream).tombstoned_at).to eq(record.timestamp)
        end

        specify "empty stream gets a sentinel at position 0" do
          write_metadata(record = meta(:StreamTombstoned))

          expect(links.map { |event_id, position, _| [event_id, position] }).to eq([[record.event_id, 0]])
          expect(repository.last_stream_version_and_tombstone(stream)).to eq([0, true])
        end

        specify "stream with entries without position gets a sentinel without position" do
          append(1, stream, ExpectedVersion.any)
          write_metadata(record = meta(:StreamTombstoned))

          expect(links.last.take(2)).to eq([record.event_id, nil])
          expect(repository.last_stream_version_and_tombstone(stream)).to eq([nil, true])
        end

        specify "makes a racing append with expected version fail on the sentinel position" do
          append(2)
          last_seen = repository.last_stream_version_and_tombstone(stream).first
          write_metadata(meta(:StreamTombstoned))

          expect { append(1, stream, ExpectedVersion.new(last_seen)) }.to raise_error(WrongExpectedEventVersion)
        end

        specify "keeps history readable" do
          events = append(3)
          write_metadata(record = meta(:StreamTombstoned))

          expect(read).to eq(events)
          expect(read(specification.stream(stream.name).backward.limit(1))).to eq([events.last])
          expect(repository.count(specification.stream(stream.name).result)).to eq(3)
          expect(repository.event_in_stream?(record.event_id, stream)).to be(false)
          expect(repository.streams_of(record.event_id)).to eq([meta_stream])
          expect { repository.position_in_stream(record.event_id, stream) }.to raise_error(EventNotFoundInStream)
          expect(repository.last_stream_event(stream).event_id).to eq(events.last)
        end
      end

      describe "restore" do
        specify "shows hidden entries in batches, newest first" do
          events = append(5)
          write_metadata(meta(:StreamSoftDeleted))
          mark_all
          write_metadata(meta(:StreamRestored))

          expect(repository.unmark_truncated(stream, 2)).to eq(2)
          expect(read).to eq(events.last(2))
          expect(repository.unmark_truncated(stream, 2)).to eq(2)
          expect(read).to eq(events.last(4))
          expect(repository.unmark_truncated(stream, 2)).to eq(1)
          expect(repository.unmark_truncated(stream, 2)).to eq(0)
          expect(read).to eq(events)
          expect(links.map(&:last)).to all(be_nil)
        end

        specify "clears soft delete and truncation" do
          append(2)
          write_metadata(meta(:StreamTruncated, before_position: 1))
          write_metadata(meta(:StreamSoftDeleted))
          write_metadata(meta(:StreamRestored))

          expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none)
          expect(mark_all).to eq(0)
        end

        specify "never shows the tombstone sentinel" do
          events = append(2)
          write_metadata(record = meta(:StreamTombstoned))
          write_metadata(meta(:StreamSoftDeleted))
          mark_all
          write_metadata(meta(:StreamRestored))

          expect(repository.unmark_truncated(stream, 10)).to eq(2)
          expect(read).to eq(events)
          expect(repository.event_in_stream?(record.event_id, stream)).to be(false)
        end

        specify "keeps tombstone and retention" do
          append(1)
          write_metadata(meta(:StreamMetadataChanged, max_count: 5, max_age: 10))
          write_metadata(tombstone = meta(:StreamTombstoned))
          write_metadata(meta(:StreamSoftDeleted))
          write_metadata(meta(:StreamRestored))

          expect(repository.stream_metadata(stream)).to eq(
            StreamMetadata.new(
              max_count: 5,
              max_age: 10,
              truncate_before: nil,
              tombstoned_at: tombstone.timestamp,
              soft_deleted_at: nil,
            ),
          )
        end

        specify "shows only entries above a boundary set again" do
          events = append(4)
          write_metadata(meta(:StreamSoftDeleted))
          mark_all
          write_metadata(meta(:StreamRestored))
          write_metadata(meta(:StreamTruncated, before_position: 2))

          expect(repository.unmark_truncated(stream, 10)).to eq(2)
          expect(read).to eq(events.drop(2))
        end

        specify "shows entries without position above an id boundary" do
          append(1, stream, ExpectedVersion.any)
          write_metadata(meta(:StreamSoftDeleted))
          mark_all
          later = append(1, stream, ExpectedVersion.any)
          EventInStream.where(event_id: later).update_all(truncated_at: Time.now.utc)
          write_metadata(meta(:StreamTruncated, before_position: 5))

          expect(repository.unmark_truncated(stream, 10)).to eq(1)
          expect(read).to eq(later)
        end

        specify "of the stream only" do
          append(1, Stream.new("other"))
          EventInStream.where(stream: "other").update_all(truncated_at: Time.now.utc)
          append(1)

          expect(repository.unmark_truncated(stream, 10)).to eq(0)
          expect(read(specification.stream("other"))).to be_empty
        end
      end

      describe "reads leave hidden entries out" do
        let!(:events) { append(6) }

        before do
          write_metadata(meta(:StreamTruncated, before_position: 3))
          mark_all
        end

        let(:visible) { events.drop(3) }
        let(:hidden) { events.take(3) }

        specify "before limit" do
          expect(read(specification.stream(stream.name).limit(2))).to eq(visible.take(2))
          expect(read(specification.stream(stream.name).backward.limit(4))).to eq(visible.reverse)
        end

        specify "of batched reads" do
          expect(repository.read(specification.stream(stream.name).in_batches(2).result).to_a.flatten.map(&:event_id)).to eq(
            visible,
          )
          expect(
            repository.read(specification.stream(stream.name).in_batches(2).as_at.result).to_a.flatten.map(&:event_id),
          ).to eq(visible)
        end

        specify "of first and last" do
          expect(repository.read(specification.stream(stream.name).read_first.result).event_id).to eq(visible.first)
          expect(repository.read(specification.stream(stream.name).read_last.result).event_id).to eq(visible.last)
          expect(repository.last_stream_event(stream).event_id).to eq(visible.last)
        end

        specify "of count" do
          expect(repository.count(specification.stream(stream.name).result)).to eq(3)
        end

        specify "of reads from and to an event" do
          expect(read(specification.stream(stream.name).from(visible.first))).to eq(visible.drop(1))
          expect(read(specification.stream(stream.name).to(visible.last))).to eq(visible.take(2))
          expect { read(specification.stream(stream.name).from(hidden.last)) }.to raise_error(EventNotFound)
          expect { read(specification.stream(stream.name).to(hidden.last)) }.to raise_error(EventNotFound)
        end

        specify "of time sorted reads" do
          expect(read(specification.stream(stream.name).as_at)).to eq(visible)
          expect(read(specification.stream(stream.name).as_of.backward)).to eq(visible.reverse)
        end

        specify "of reads by event type and id" do
          expect(read(specification.stream(stream.name).of_type("SRecordTestEvent"))).to eq(visible)
          expect(read(specification.stream(stream.name).with_id([hidden.first, visible.first]))).to eq([visible.first])
        end

        specify "but not of the global stream" do
          expect(read(specification).take(6)).to eq(events)
        end

        specify "as absent in position_in_stream" do
          expect { repository.position_in_stream(hidden.first, stream) }.to raise_error(EventNotFoundInStream)
          expect(repository.position_in_stream(visible.first, stream)).to eq(3)
        end

        specify "as absent in event_in_stream?" do
          expect(repository.event_in_stream?(hidden.first, stream)).to be(false)
          expect(repository.event_in_stream?(visible.first, stream)).to be(true)
        end

        specify "as absent in streams_of" do
          repository.link_to_stream([hidden.first], Stream.new("other"), ExpectedVersion.any)

          expect(repository.streams_of(hidden.first)).to eq([Stream.new("other")])
          expect(repository.streams_of(visible.first)).to eq([stream])
        end

        specify "but counts them in last stream version" do
          write_metadata(meta(:StreamSoftDeleted))
          mark_all
          later = append(1)

          expect(repository.position_in_stream(later.first, stream)).to eq(6)
        end
      end

      specify "append and soft delete in one transaction marks every appended event" do
        events = nil
        helper.with_transaction do
          events = append(3)
          write_metadata(meta(:StreamSoftDeleted))
          mark_all
        end

        expect(read).to be_empty
        expect(links.map(&:first)).to eq(events)
        expect(links.map(&:last)).to all(be_present)
      end
    end
  end
end
