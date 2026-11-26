# frozen_string_literal: true

require "spec_helper"
require "forwardable"
require "ruby_event_store/spec/event_repository_lint"
require "ruby_event_store/spec/stream_metadata_lint"

module RubyEventStore
  # Repository with the ordinary interface only, no native support for stream metadata.
  class PlainRepository
    extend Forwardable

    def_delegators :@repository,
                   :append_to_stream,
                   :link_to_stream,
                   :delete_stream,
                   :has_event?,
                   :last_stream_event,
                   :read,
                   :count,
                   :update_messages,
                   :streams_of,
                   :position_in_stream,
                   :global_position,
                   :event_in_stream?

    def initialize(repository = InMemoryRepository.new)
      @repository = repository
    end
  end

  ::RSpec.describe StreamMetadataAwareRepository do
    helper = SpecHelper.new

    it_behaves_like "event repository", -> { StreamMetadataAwareRepository.new(InMemoryRepository.new) }, helper
    it_behaves_like "event repository", -> { StreamMetadataAwareRepository.new(PlainRepository.new) }, helper
    it_behaves_like "stream metadata", -> { InMemoryRepository.new }, helper

    let(:inner) { InMemoryRepository.new }
    let(:repository) { StreamMetadataAwareRepository.new(inner) }
    let(:stream) { Stream.new("some") }
    let(:global_stream) { Stream.new(GLOBAL_STREAM) }
    let(:time) { Time.utc(2026, 11, 18, 12, 0, 0) }

    def ids(repository, stream)
      repository.read(Specification.new(nil).stream(stream.name).result).map(&:event_id)
    end

    def append(repository, stream, count, expected_version = ExpectedVersion.auto)
      records = Array.new(count) { SRecord.new }
      repository.append_to_stream(records, stream, expected_version)
      records.map(&:event_id)
    end

    describe "append and link" do
      specify "turn :auto into the version read together with the tombstone flag" do
        append(inner, stream, 2)
        records = [SRecord.new]

        expect(inner).to receive(:append_to_stream).with(records, stream, ExpectedVersion.new(1))
        expect(inner).to receive(:link_to_stream).with(["a"], stream, ExpectedVersion.new(1))

        repository.append_to_stream(records, stream, ExpectedVersion.auto)
        repository.link_to_stream(["a"], stream, ExpectedVersion.auto)
      end

      specify "turn :auto into :none for an empty stream" do
        records = [SRecord.new]

        expect(inner).to receive(:append_to_stream).with(records, stream, ExpectedVersion.new(-1))

        repository.append_to_stream(records, stream, ExpectedVersion.auto)
      end

      specify "do not ask the registry for :auto on a native repository" do
        registry = instance_double(StreamMetadataRegistry)
        repository = StreamMetadataAwareRepository.new(inner, registry: registry)

        append(repository, stream, 1)
      end

      specify "pass other expected versions unchanged after asking the registry" do
        registry = instance_double(StreamMetadataRegistry, tombstoned?: false)
        repository = StreamMetadataAwareRepository.new(inner, registry: registry)
        records = [SRecord.new]

        expect(inner).to receive(:append_to_stream).with(records, stream, ExpectedVersion.none)
        expect(inner).to receive(:link_to_stream).with(["a"], stream, ExpectedVersion.any)

        repository.append_to_stream(records, stream, ExpectedVersion.none)
        repository.link_to_stream(["a"], stream, ExpectedVersion.any)
        expect(registry).to have_received(:tombstoned?).with(stream).twice
      end

      specify "pass the global stream unchanged without asking the registry" do
        registry = instance_double(StreamMetadataRegistry)
        repository = StreamMetadataAwareRepository.new(inner, registry: registry)
        records = [SRecord.new]

        expect(inner).to receive(:append_to_stream).with(records, global_stream, ExpectedVersion.any)

        repository.append_to_stream(records, global_stream, ExpectedVersion.any)
      end

      specify "see a tombstone of another process after the registry ttl" do
        now = 0
        other_process = StreamMetadataAwareRepository.new(inner)
        repository =
          StreamMetadataAwareRepository.new(inner, registry: StreamMetadataRegistry.new(inner, ttl: 5, clock: -> { now }))
        append(repository, stream, 1, ExpectedVersion.any)

        other_process.tombstone_stream(stream, expected_version: ExpectedVersion.any)

        now = 4
        expect { append(repository, stream, 1, ExpectedVersion.any) }.not_to raise_error
        now = 9
        expect { append(repository, stream, 1, ExpectedVersion.any) }.to raise_error(StreamTombstoned)
      end
    end

    describe "metadata" do
      specify "validates retention" do
        [0, -1, "1", 1.5].each do |value|
          expect do
            repository.set_stream_metadata(stream, max_count: value, max_age: nil, expected_version: ExpectedVersion.any)
          end.to raise_error(InvalidStreamMetadata)
          expect do
            repository.set_stream_metadata(stream, max_count: nil, max_age: value, expected_version: ExpectedVersion.any)
          end.to raise_error(InvalidStreamMetadata)
        end
        expect(inner.read(Specification.new(nil).result).to_a).to be_empty
      end

      specify "validates truncation position" do
        [-1, "1", nil, 1.0].each do |value|
          expect do
            repository.truncate_stream(stream, before: value, expected_version: ExpectedVersion.any)
          end.to raise_error(InvalidStreamMetadata)
        end
        expect do
          repository.truncate_stream(stream, before: 0, expected_version: ExpectedVersion.any)
        end.not_to raise_error
      end

      specify "refuses metadata of the global stream" do
        expect { repository.stream_metadata(global_stream) }.to raise_error(InvalidStreamMetadata)
        expect { repository.soft_delete_stream(global_stream, expected_version: ExpectedVersion.any) }.to raise_error(
          InvalidStreamMetadata,
        )
      end

      specify "writes metadata records" do
        repository =
          StreamMetadataAwareRepository.new(inner, clock: -> { time })
        repository.set_stream_metadata(stream, max_count: 3, max_age: nil, expected_version: ExpectedVersion.any)

        record = inner.read(Specification.new(nil).stream("$$some").result).first
        expect(record).to have_attributes(
          event_type: "RubyEventStore::StreamMetadataEvents::StreamMetadataChanged",
          data: { "stream" => "some", "max_count" => 3, "max_age" => nil },
          metadata: {},
          timestamp: time,
          valid_at: time,
        )
        expect(record.event_id).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
      end

      specify "take timestamp and validity of metadata records from the metadata given" do
        repository = StreamMetadataAwareRepository.new(inner, clock: -> { time })
        timestamp = Time.utc(2026, 1, 1)
        valid_at = Time.utc(2025, 1, 1)

        repository.tombstone_stream(
          stream,
          expected_version: ExpectedVersion.any,
          metadata: { correlation_id: "c", timestamp: timestamp, valid_at: valid_at },
        )
        repository.tombstone_stream(Stream.new("other"), expected_version: ExpectedVersion.any, metadata: { timestamp: timestamp })
        repository.tombstone_stream(Stream.new("third"), expected_version: ExpectedVersion.any, metadata: { correlation_id: "d" })

        records = inner.read(Specification.new(nil).result).to_a
        expect(records.map { |record| [record.metadata, record.timestamp, record.valid_at] }).to eq(
          [[{ correlation_id: "c" }, timestamp, valid_at], [{}, timestamp, timestamp], [{ correlation_id: "d" }, time, time]],
        )
      end

      specify "pass metadata of every metadata record" do
        append(inner, stream, 1)

        repository.set_stream_metadata(stream, max_count: 1, max_age: nil, expected_version: ExpectedVersion.any, metadata: { n: 1 })
        repository.truncate_stream(stream, before: 1, expected_version: ExpectedVersion.any, metadata: { n: 2 })
        repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any, metadata: { n: 3 })
        repository.restore_stream(stream, expected_version: ExpectedVersion.any, metadata: { n: 4 })
        repository.tombstone_stream(stream, expected_version: ExpectedVersion.any, metadata: { n: 5 })

        expect(inner.read(Specification.new(nil).stream("$$some").result).map(&:metadata)).to eq(
          [{ n: 1 }, { n: 2 }, { n: 3 }, { n: 4 }, { n: 5 }],
        )
      end

      specify "return self" do
        expect(
          repository.set_stream_metadata(stream, max_count: 3, max_age: nil, expected_version: ExpectedVersion.any),
        ).to be(repository)
        expect(repository.truncate_stream(stream, before: 1, expected_version: ExpectedVersion.any)).to be(repository)
        expect(repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any)).to be(repository)
        expect(repository.tombstone_stream(stream, expected_version: ExpectedVersion.any)).to be(repository)
      end

      specify "restore reports entries already removed" do
        append(inner, stream, 4)
        repository.tombstone_stream(stream, expected_version: ExpectedVersion.any)
        repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any)
        inner.instance_variable_get(:@streams).fetch("some").delete_at(1)

        expect(repository.restore_stream(stream, expected_version: ExpectedVersion.any)).to eq(
          StreamMetadataAwareRepository::StreamRestore.new(restored: 3, missing: 1),
        )
      end

      specify "restore reports nothing removed for a tombstoned stream" do
        append(inner, stream, 2)
        repository.tombstone_stream(stream, expected_version: ExpectedVersion.any)
        repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any)

        expect(repository.restore_stream(stream, expected_version: ExpectedVersion.any)).to eq(
          StreamMetadataAwareRepository::StreamRestore.new(restored: 2, missing: 0),
        )
      end

      specify "restore reports no removed count for a stream without positions" do
        append(inner, stream, 2, ExpectedVersion.any)
        repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any)

        expect(repository.restore_stream(stream, expected_version: ExpectedVersion.any)).to eq(
          StreamMetadataAwareRepository::StreamRestore.new(restored: 2, missing: nil),
        )
      end

      specify "checks expected version of truncate, soft delete, restore and tombstone" do
        append(inner, stream, 2)

        expect do
          repository.truncate_stream(stream, before: 1, expected_version: ExpectedVersion.new(0))
        end.to raise_error(WrongExpectedEventVersion)
        expect { repository.soft_delete_stream(stream, expected_version: ExpectedVersion.none) }.to raise_error(
          WrongExpectedEventVersion,
        )
        expect { repository.restore_stream(stream, expected_version: ExpectedVersion.new(5)) }.to raise_error(
          WrongExpectedEventVersion,
        )
        expect { repository.tombstone_stream(stream, expected_version: ExpectedVersion.new(0)) }.to raise_error(
          WrongExpectedEventVersion,
        )
        expect(ids(inner, Stream.new("$$some"))).to be_empty
      end
    end

    describe "delete_stream" do
      def meta_types(inner)
        inner.read(Specification.new(nil).stream("$$some").result).map(&:event_type)
      end

      specify "refuses a tombstoned stream and keeps its entries and sentinel" do
        event_ids = append(inner, stream, 2)
        repository.tombstone_stream(stream, expected_version: ExpectedVersion.any)

        expect { repository.delete_stream(stream) }.to raise_error(StreamTombstoned)
        expect(ids(inner, stream)).to eq(event_ids)
        expect(inner.last_stream_version_and_tombstone(stream)).to eq([2, true])
      end

      specify "refuses a tombstoned stream without native support" do
        repository = StreamMetadataAwareRepository.new(PlainRepository.new)
        append(repository, stream, 1)
        repository.tombstone_stream(stream, expected_version: ExpectedVersion.any)

        expect { repository.delete_stream(stream) }.to raise_error(StreamTombstoned)
        expect(ids(repository, stream).size).to eq(1)
      end

      specify "restores the metadata of a soft deleted stream" do
        append(inner, stream, 3)
        repository.set_stream_metadata(stream, max_count: 5, max_age: nil, expected_version: ExpectedVersion.any)
        repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any)

        repository.delete_stream(stream)

        expect(ids(inner, stream)).to be_empty
        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none.with(max_count: 5))
        expect(meta_types(inner).last).to eq(StreamMetadataEvents::StreamRestored.name)
        event_ids = append(repository, stream, 2)
        expect(ids(inner, stream)).to eq(event_ids)
      end

      specify "restores the metadata of a truncated stream" do
        append(inner, stream, 3)
        repository.truncate_stream(stream, before: 2, expected_version: ExpectedVersion.any)

        repository.delete_stream(stream)

        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none)
        expect(meta_types(inner).last).to eq(StreamMetadataEvents::StreamRestored.name)
      end

      specify "restores the metadata of a soft deleted empty stream" do
        repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any)

        repository.delete_stream(stream)

        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none)
      end

      specify "writes nothing for a stream with retention only or no metadata" do
        append(inner, stream, 1)
        append(inner, Stream.new("other"), 1)
        repository.set_stream_metadata(stream, max_count: 5, max_age: nil, expected_version: ExpectedVersion.any)

        repository.delete_stream(stream)
        repository.delete_stream(Stream.new("other"))

        expect(meta_types(inner)).to eq([StreamMetadataEvents::StreamMetadataChanged.name])
        expect(inner.read(Specification.new(nil).stream("$$other").result).to_a).to be_empty
        expect(ids(inner, Stream.new("other"))).to be_empty
      end

      specify "writes nothing without native support" do
        inner = PlainRepository.new
        repository = StreamMetadataAwareRepository.new(inner)
        allow(repository).to receive(:stream_metadata).and_return(StreamMetadata.none.with(truncate_before: 1))
        append(inner, stream, 1)

        repository.delete_stream(stream)

        expect(ids(inner, Stream.new("$$some"))).to be_empty
        expect(ids(inner, stream)).to be_empty
      end

      specify "writes StreamRestored with the metadata given and yields it when publishing" do
        repository = StreamMetadataAwareRepository.new(inner, publish_metadata_events: true)
        append(inner, stream, 1)
        repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any)
        yielded = []

        repository.delete_stream(stream, metadata: { correlation_id: "c" }) { |record| yielded << record }
        repository.delete_stream(stream, metadata: { correlation_id: "d" }) { |record| yielded << record }

        expect(yielded.map(&:event_type)).to eq([StreamMetadataEvents::StreamRestored.name])
        expect(yielded.first.metadata).to eq(correlation_id: "c")
        expect(inner.read(Specification.new(nil).stream("$$some").result).to_a.last).to eq(yielded.first)
      end

      specify "yields nothing when not publishing" do
        append(inner, stream, 1)
        repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any)
        yielded = []

        repository.delete_stream(stream) { |record| yielded << record }

        expect(yielded).to be_empty
      end

      specify "returns what the repository returns" do
        allow(inner).to receive(:delete_stream).with(stream).and_return(:deleted)

        expect(repository.delete_stream(stream)).to be(:deleted)
      end

      specify "passes reserved and global streams to the repository without a metadata lookup" do
        append(inner, Stream.new("$$some"), 1, ExpectedVersion.any)
        allow(inner).to receive(:stream_metadata)
        allow(inner).to receive(:delete_stream).and_call_original

        repository.delete_stream(Stream.new("$$some"))
        repository.delete_stream(global_stream)

        expect(inner).not_to have_received(:stream_metadata)
        expect(inner).to have_received(:delete_stream).with(global_stream)
        expect(ids(inner, Stream.new("$$some"))).to be_empty
      end
    end

    describe "publishing metadata events" do
      let(:repository) { StreamMetadataAwareRepository.new(inner, publish_metadata_events: true) }

      specify "yields each record written once the operation is complete" do
        append(inner, stream, 2)
        yielded = []

        expect(
          repository.set_stream_metadata(stream, max_count: 1, max_age: nil, expected_version: ExpectedVersion.any) do |record|
            yielded << record
          end,
        ).to be(repository)
        expect(
          repository.truncate_stream(stream, before: 1, expected_version: ExpectedVersion.any) do |record|
            expect(inner.event_in_stream?(ids(inner, global_stream).first, stream)).to be(false)
            yielded << record
          end,
        ).to be(repository)
        expect(
          repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any) do |record|
            expect(ids(inner, stream)).to be_empty
            yielded << record
          end,
        ).to be(repository)
        expect(
          repository.restore_stream(stream, expected_version: ExpectedVersion.any) do |record|
            expect(ids(inner, stream).size).to eq(2)
            yielded << record
          end,
        ).to eq(StreamMetadataAwareRepository::StreamRestore.new(restored: 2, missing: 0))
        expect(
          repository.tombstone_stream(stream, expected_version: ExpectedVersion.any) do |record|
            expect { append(repository, stream, 1, ExpectedVersion.any) }.to raise_error(StreamTombstoned)
            yielded << record
          end,
        ).to be(repository)

        expect(yielded).to eq(inner.read(Specification.new(nil).stream("$$some").result).to_a)
      end

      specify "needs a block" do
        expect(
          repository.set_stream_metadata(stream, max_count: 1, max_age: nil, expected_version: ExpectedVersion.any),
        ).to be(repository)
      end

      specify "yields on a repository without native support" do
        repository = StreamMetadataAwareRepository.new(PlainRepository.new, publish_metadata_events: true)
        yielded = []

        repository.set_stream_metadata(stream, max_count: 1, max_age: nil, expected_version: ExpectedVersion.any) do |record|
          yielded << record.event_type
        end
        repository.tombstone_stream(stream, expected_version: ExpectedVersion.any) { |record| yielded << record.event_type }

        expect(yielded).to eq(
          [StreamMetadataEvents::StreamMetadataChanged.name, StreamMetadataEvents::StreamTombstoned.name],
        )
      end

      specify "yields nothing by default" do
        repository = StreamMetadataAwareRepository.new(inner)
        append(inner, stream, 1)
        yielded = []

        repository.set_stream_metadata(stream, max_count: 1, max_age: nil, expected_version: ExpectedVersion.any) do |record|
          yielded << record
        end
        repository.truncate_stream(stream, before: 1, expected_version: ExpectedVersion.any) { |record| yielded << record }
        repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any) { |record| yielded << record }
        repository.restore_stream(stream, expected_version: ExpectedVersion.any) { |record| yielded << record }
        repository.tombstone_stream(stream, expected_version: ExpectedVersion.any) { |record| yielded << record }

        expect(yielded).to be_empty
      end
    end

    describe "repository without native support" do
      let(:inner) { PlainRepository.new }

      specify "refuses truncate, soft delete and restore" do
        expect { repository.truncate_stream(stream, before: 1, expected_version: ExpectedVersion.any) }.to raise_error(
          StreamMetadataNotSupported,
        )
        expect { repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any) }.to raise_error(
          StreamMetadataNotSupported,
        )
        expect { repository.restore_stream(stream, expected_version: ExpectedVersion.any) }.to raise_error(
          StreamMetadataNotSupported,
        )
      end

      specify "treats a repository that denies native support as one without it" do
        inner = InMemoryRepository.new
        allow(inner).to receive(:supports_native_truncation?).and_return(false)
        repository = StreamMetadataAwareRepository.new(inner)

        expect { repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any) }.to raise_error(
          StreamMetadataNotSupported,
        )
      end

      specify "keeps retention and tombstone in the meta stream" do
        repository = StreamMetadataAwareRepository.new(inner, clock: -> { time })
        append(inner, stream, 1)

        repository.set_stream_metadata(stream, max_count: 3, max_age: 60, expected_version: ExpectedVersion.any)
        repository.set_stream_metadata(stream, max_count: nil, max_age: 30, expected_version: ExpectedVersion.new(0))
        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none.with(max_age: 30))
        repository.set_stream_metadata(stream, max_count: 7, max_age: nil, expected_version: ExpectedVersion.new(0))
        repository.tombstone_stream(stream, expected_version: ExpectedVersion.auto)
        inner.append_to_stream(
          [SRecord.new(event_type: StreamMetadataEvents::StreamScavenged.name, data: { "stream" => "some" })],
          Stream.new("$$some"),
          ExpectedVersion.any,
        )

        expect(repository.stream_metadata(stream)).to eq(StreamMetadata.none.with(max_count: 7, tombstoned_at: time))
        expect(repository.stream_metadata(Stream.new("other"))).to eq(StreamMetadata.none)
        expect(ids(inner, Stream.new("$$some")).size).to eq(5)
      end

      specify "checks expected version by the number of entries" do
        append(inner, stream, 2)

        [ExpectedVersion.new(0), ExpectedVersion.new(2), ExpectedVersion.none].each do |expected_version|
          expect do
            repository.set_stream_metadata(stream, max_count: 1, max_age: nil, expected_version: expected_version)
          end.to raise_error(WrongExpectedEventVersion)
        end
        expect(ids(inner, Stream.new("$$some"))).to be_empty
        expect do
          repository.set_stream_metadata(stream, max_count: 1, max_age: nil, expected_version: ExpectedVersion.new(1))
          repository.tombstone_stream(Stream.new("other"), expected_version: ExpectedVersion.none)
        end.not_to raise_error
      end

      specify "blocks writes to a tombstoned stream with every expected version" do
        event_ids = append(inner, stream, 1)
        repository.tombstone_stream(stream, expected_version: ExpectedVersion.any)

        [ExpectedVersion.auto, ExpectedVersion.any, ExpectedVersion.new(0)].each do |expected_version|
          expect { append(repository, stream, 1, expected_version) }.to raise_error(StreamTombstoned)
          expect { repository.link_to_stream(event_ids, stream, expected_version) }.to raise_error(StreamTombstoned)
        end
        expect(ids(repository, stream)).to eq(event_ids)
        expect { repository.tombstone_stream(stream, expected_version: ExpectedVersion.any) }.to raise_error(
          StreamTombstoned,
        )
      end
    end

    specify "passes other methods to the repository" do
      inner.define_singleton_method(:other) { :result }

      expect(repository).to respond_to(:other)
      expect(repository.other).to be(:result)
      expect(repository).not_to respond_to(:no_such_method)
      expect { repository.no_such_method }.to raise_error(NoMethodError) do |error|
        expect(error.receiver).to be(repository)
      end
    end

    specify "keeps the native tier to itself" do
      %i[
        supports_native_truncation?
        last_stream_version_and_tombstone
        append_stream_metadata
        mark_truncated
        unmark_truncated
      ].each do |method_name|
        expect(repository).not_to respond_to(method_name)
        expect { repository.public_send(method_name) }.to raise_error(NoMethodError) do |error|
          expect(error.receiver).to be(repository)
        end
      end
    end

    specify "marks and restores in batches of 1000 by default" do
      append(inner, stream, 1)
      expect(inner).to receive(:mark_truncated).with(stream, 1_000).twice.and_call_original
      expect(inner).to receive(:unmark_truncated).with(stream, 1_000).twice.and_call_original

      repository.soft_delete_stream(stream, expected_version: ExpectedVersion.any)
      repository.restore_stream(stream, expected_version: ExpectedVersion.any)
    end

    specify "stamps metadata records with the current time in UTC with stored precision" do
      allow(Time).to receive(:now).and_return(Time.at(1, 123_456_789, :nsec, in: "+01:00"))

      repository.tombstone_stream(stream, expected_version: ExpectedVersion.any)

      timestamp = repository.stream_metadata(stream).tombstoned_at
      expect(timestamp).to eq(Time.at(1, 123_457, :usec))
      expect(timestamp).to be_utc
    end

    specify "passes arguments to other methods" do
      inner.define_singleton_method(:other) { |*arguments, **keyword_arguments, &block| [arguments, keyword_arguments, block.call] }

      expect(repository.other(1, key: 2) { 3 }).to eq([[1], { key: 2 }, 3])
    end
  end

  ::RSpec.describe StreamMetadataRegistry do
    let(:repository) { InMemoryRepository.new }
    let(:now) { [0] }
    let(:registry) { StreamMetadataRegistry.new(repository, ttl: 5, clock: -> { now.first }) }

    def tombstone(repository, stream_name)
      record =
        SRecord.new(event_type: StreamMetadataEvents::StreamTombstoned.name, data: { "stream" => stream_name })
      repository.append_to_stream([record], Stream.new("$$#{stream_name}"), ExpectedVersion.any)
    end

    specify "reads tombstones on first lookup" do
      tombstone(repository, "a")
      repository.append_to_stream([SRecord.new(data: { "stream" => "b" })], Stream.new("$$b"), ExpectedVersion.any)

      expect(registry.tombstoned?(Stream.new("a"))).to be(true)
      expect(registry.tombstoned?(Stream.new("b"))).to be(false)
    end

    specify "rereads only after ttl" do
      registry.tombstoned?(Stream.new("a"))
      tombstone(repository, "a")

      now[0] = 4.9
      expect(registry.tombstoned?(Stream.new("a"))).to be(false)
      now[0] = 5
      expect(registry.tombstoned?(Stream.new("a"))).to be(true)
    end

    specify "rereads when more than ttl passed" do
      registry.tombstoned?(Stream.new("a"))
      tombstone(repository, "a")

      now[0] = 7
      expect(registry.tombstoned?(Stream.new("a"))).to be(true)
    end

    specify "reads once for concurrent lookups" do
      reads = 0
      allow(repository).to receive(:read).and_wrap_original do |original, specification|
        reads += 1
        sleep 0.05
        original.call(specification)
      end

      Array.new(2) { Thread.new { registry.tombstoned?(Stream.new("a")) } }.each(&:join)

      expect(reads).to eq(1)
    end

    specify "adds a tombstone only after a read in progress" do
      events = Queue.new
      allow(repository).to receive(:read).and_wrap_original do |original, specification|
        events << :read_started
        sleep 0.05
        events << :read_finished
        original.call(specification)
      end
      reader = Thread.new { registry.tombstoned?(Stream.new("a")) }
      sleep 0.01 until events.size.positive?

      registry.tombstone(Stream.new("a"))
      events << :tombstoned
      reader.join

      expect(Array.new(events.size) { events.pop }).to eq(%i[read_started read_finished tombstoned])
    end

    specify "measures ttl from the last read" do
      registry.tombstoned?(Stream.new("a"))
      now[0] = 5
      registry.tombstoned?(Stream.new("a"))
      tombstone(repository, "a")

      now[0] = 9
      expect(registry.tombstoned?(Stream.new("a"))).to be(false)
      now[0] = 10
      expect(registry.tombstoned?(Stream.new("a"))).to be(true)
    end

    specify "rereads only what is new" do
      tombstone(repository, "a")
      registry.tombstoned?(Stream.new("a"))
      tombstone(repository, "b")
      now[0] = 5

      expect(repository).to receive(:read).and_wrap_original do |original, specification|
        expect(specification.start).not_to be_nil
        original.call(specification)
      end
      expect(registry.tombstoned?(Stream.new("b"))).to be(true)
      expect(registry.tombstoned?(Stream.new("a"))).to be(true)
    end

    specify "reads in batches" do
      expect(repository).to receive(:read).and_wrap_original do |original, specification|
        expect(specification).to have_attributes(batched?: true, batch_size: 1_000)
        original.call(specification)
      end

      registry.tombstoned?(Stream.new("a"))
    end

    specify "reads every batch" do
      1_001.times { |index| tombstone(repository, "s#{index}") }

      expect(registry.tombstoned?(Stream.new("s0"))).to be(true)
      expect(registry.tombstoned?(Stream.new("s1000"))).to be(true)
    end

    specify "learns of a tombstone at once" do
      registry.tombstoned?(Stream.new("a"))

      registry.tombstone(Stream.new("a"))

      expect(registry.tombstoned?(Stream.new("a"))).to be(true)
    end

    specify "reads again after a failed read" do
      allow(repository).to receive(:read).and_raise(RuntimeError)
      expect { registry.tombstoned?(Stream.new("a")) }.to raise_error(RuntimeError)
      allow(repository).to receive(:read).and_call_original
      tombstone(repository, "a")

      expect(registry.tombstoned?(Stream.new("a"))).to be(true)
    end

    specify "uses monotonic clock by default" do
      expect(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC).and_return(0)

      StreamMetadataRegistry.new(repository).tombstoned?(Stream.new("a"))
    end

    specify "defaults ttl to 5 seconds" do
      clock = [0]
      registry = StreamMetadataRegistry.new(repository, clock: -> { clock.first })
      registry.tombstoned?(Stream.new("a"))
      tombstone(repository, "a")

      clock[0] = 4
      expect(registry.tombstoned?(Stream.new("a"))).to be(false)
      clock[0] = 5
      expect(registry.tombstoned?(Stream.new("a"))).to be(true)
    end
  end
end
