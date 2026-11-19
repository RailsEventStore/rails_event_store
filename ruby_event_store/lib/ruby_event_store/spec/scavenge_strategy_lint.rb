# frozen_string_literal: true

# Contract of a scavenge strategy: the storage specific part of the scavenger, which turns
# the stream metadata of a native repository (see the "stream metadata" lint) into physical
# removal of hidden entries. The scavenger runner (gem ruby_event_store-scavenger) calls it.
#
#   it_behaves_like "scavenge strategy", mk_repository, mk_strategy
#
# mk_repository returns a new, empty native repository (not decorated); mk_strategy a strategy
# working on the same storage. The repository only sets up the data.
#
# A run goes stream by stream: MARK hides entries the metadata says should be hidden, SWEEP
# removes entries that have been hidden long enough. A stream is never swept before it is
# marked, so readers see an entry disappear from reads first and from storage later.
#
#   streams(after:, limit:) => [Stream]
#     Streams with metadata, ordered by name, at most limit of them, those with a name
#     greater than after (every one when after is nil). Meta streams are never listed.
#
#   plan(stream, now:, sweep_before:) => Scavenger::Plan
#     Changes nothing. The boundary is the furthest of:
#       truncate_before / soft_delete - the hide boundary recorded by truncate_stream /
#                                       soft_delete_stream (marking interrupted midway is
#                                       finished by the scavenger)
#       max_count                     - every visible entry but the max_count newest
#       max_age                       - every visible entry linked to the stream before
#                                       now - max_age (link time, not the event's timestamp)
#     A tombstone hides nothing. to_mark counts visible entries up to the boundary; to_sweep
#     counts hidden entries marked before sweep_before, leaving out the position anchor and
#     the tombstone sentinel.
#
#   mark(plan, batch_size, now:) => Integer
#     Hides at most batch_size visible entries of plan.stream up to plan.boundary, oldest
#     first, in one transaction, as marked at now. Returns how many it hid; 0 when none is left.
#     The boundary identifies entries, so entries appended after the plan stay visible.
#
#   sweep(stream, batch_size, before:) => Integer
#     Removes at most batch_size links of hidden entries marked before before, oldest first,
#     in one transaction. Never removes a visible entry, the position anchor (the entry with
#     the highest position, the newest entry when entries have no position) or the tombstone
#     sentinel, so the last stream version and the tombstone survive a full sweep. Events stay
#     in the global stream. Returns how many it removed; 0 when none is left.
#
# Every call is idempotent on the state it finds: repeating a run after an interruption
# finishes it.

require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  ::RSpec.shared_examples "scavenge strategy" do |mk_repository, mk_strategy|
    let(:repository) { mk_repository.call }
    let(:strategy) { mk_strategy.call }
    let(:stream) { Stream.new("scavenge-#{SecureRandom.uuid}") }
    let(:other_stream) { Stream.new("scavenge-#{SecureRandom.uuid}") }
    let(:far_future) { Time.now.utc + 365 * 24 * 3600 }

    def append(stream, count, expected_version = ExpectedVersion.auto, **record)
      records = Array.new(count) { SRecord.new(**record) }
      repository.append_to_stream(records, stream, expected_version)
      records.map(&:event_id)
    end

    def write(event_class, stream, **data)
      record =
        Record.new(
          event_id: SecureRandom.uuid,
          event_type: event_class.name,
          data: { "stream" => stream.name }.merge(data.transform_keys(&:to_s)),
          metadata: {
          },
          timestamp: Time.now.utc.round(TIMESTAMP_PRECISION),
          valid_at: Time.now.utc.round(TIMESTAMP_PRECISION),
        )
      repository.append_stream_metadata(record, stream, ExpectedVersion.any)
      record
    end

    def mark_truncated(stream)
      nil until repository.mark_truncated(stream, 100).zero?
    end

    def retain(stream, max_count: nil, max_age: nil)
      write(StreamMetadataEvents::StreamMetadataChanged, stream, max_count: max_count, max_age: max_age)
    end

    def truncate(stream, before_position)
      write(StreamMetadataEvents::StreamTruncated, stream, before_position: before_position)
    end

    def soft_delete(stream)
      write(StreamMetadataEvents::StreamSoftDeleted, stream)
    end

    def tombstone(stream)
      write(StreamMetadataEvents::StreamTombstoned, stream)
    end

    def restore(stream)
      write(StreamMetadataEvents::StreamRestored, stream)
      nil until repository.unmark_truncated(stream, 100).zero?
    end

    def plan(stream, now: Time.now.utc, sweep_before: Time.now.utc)
      strategy.plan(stream, now: now, sweep_before: sweep_before)
    end

    def mark(stream, now: Time.now.utc)
      plan = plan(stream, now: now)
      marked = 0
      while (batch = strategy.mark(plan, 100, now: now)).positive?
        marked += batch
      end
      marked
    end

    def sweep(stream, before: far_future)
      swept = 0
      while (batch = strategy.sweep(stream, 100, before: before)).positive?
        swept += batch
      end
      swept
    end

    def read_ids(stream)
      repository.read(Specification.new(nil).stream(stream.name).result).map(&:event_id)
    end

    def global_ids
      repository.read(Specification.new(nil).result).map(&:event_id)
    end

    def last_version_and_tombstone(stream)
      repository.last_stream_version_and_tombstone(stream)
    end

    describe "streams" do
      specify "lists streams with metadata ordered by name" do
        streams = Array.new(3) { Stream.new("scavenge-#{SecureRandom.uuid}") }
        streams.each { |stream| retain(stream, max_count: 1) }
        append(other_stream, 1)

        expect(strategy.streams(after: nil, limit: 10)).to eq(streams.sort_by(&:name))
      end

      specify "lists streams with any metadata" do
        a, b, c, d = %w[scavenge-a scavenge-b scavenge-c scavenge-d].map { |name| Stream.new(name) }
        retain(a, max_age: 60)
        truncate(b, 0)
        soft_delete(c)
        tombstone(d)

        expect(strategy.streams(after: nil, limit: 10)).to eq([a, b, c, d])
      end

      specify "lists streams after a cursor, at most limit of them" do
        a, b, c, d = %w[scavenge-a scavenge-b scavenge-c scavenge-d].map { |name| Stream.new(name) }
        [d, b, a, c].each { |stream| retain(stream, max_count: 1) }

        expect(strategy.streams(after: nil, limit: 2)).to eq([a, b])
        expect(strategy.streams(after: "scavenge-b", limit: 2)).to eq([c, d])
        expect(strategy.streams(after: "scavenge-bb", limit: 2)).to eq([c, d])
        expect(strategy.streams(after: "scavenge-d", limit: 2)).to eq([])
      end

      specify "lists no meta streams" do
        retain(stream, max_count: 1)

        expect(strategy.streams(after: nil, limit: 10)).to eq([stream])
      end

      specify "lists nothing without metadata" do
        append(stream, 2)

        expect(strategy.streams(after: nil, limit: 10)).to eq([])
      end
    end

    describe "plan" do
      specify "of a stream without metadata" do
        append(stream, 2)

        expect(plan(stream)).to eq(
          Scavenger::Plan.new(stream: stream, boundary: nil, reasons: [], to_mark: 0, to_sweep: 0),
        )
      end

      specify "of a stream with retention that holds nothing to hide" do
        append(stream, 2)
        retain(stream, max_count: 2, max_age: 3600)

        plan = plan(stream)

        expect(plan.boundary).to be_nil
        expect(plan.reasons).to eq([])
        expect(plan).to be_empty
      end

      specify "of an empty stream with metadata" do
        retain(stream, max_count: 1, max_age: 1)

        expect(plan(stream, now: far_future)).to be_empty
      end

      specify "finishes a truncation" do
        append(stream, 5)
        truncate(stream, 3)

        plan = plan(stream)

        expect(plan.reasons).to eq([:truncate_before])
        expect(plan.to_mark).to eq(3)
        expect(plan.to_sweep).to eq(0)
      end

      specify "finishes a soft delete" do
        append(stream, 4)
        soft_delete(stream)

        plan = plan(stream)

        expect(plan.reasons).to eq([:soft_delete])
        expect(plan.to_mark).to eq(4)
      end

      specify "counts only entries not marked yet" do
        append(stream, 5)
        truncate(stream, 3)
        repository.mark_truncated(stream, 2)

        expect(plan(stream).to_mark).to eq(1)
      end

      specify "keeps the reason of a finished truncation" do
        append(stream, 5)
        truncate(stream, 3)
        mark_truncated(stream)

        plan = plan(stream)

        expect(plan.reasons).to eq([:truncate_before])
        expect(plan.to_mark).to eq(0)
      end

      specify "keeps the max_count newest entries" do
        append(stream, 5)
        retain(stream, max_count: 2)

        plan = plan(stream)

        expect(plan.reasons).to eq([:max_count])
        expect(plan.to_mark).to eq(3)
      end

      specify "keeps the max_count newest visible entries" do
        append(stream, 5)
        truncate(stream, 2)
        mark_truncated(stream)
        retain(stream, max_count: 2)

        plan = plan(stream)

        expect(plan.reasons).to eq(%i[truncate_before max_count])
        expect(plan.to_mark).to eq(1)
      end

      specify "max_count of exactly the visible entries hides nothing" do
        append(stream, 3)
        retain(stream, max_count: 3)

        expect(plan(stream)).to be_empty
        expect(plan(stream).reasons).to eq([])
      end

      specify "max_count of entries without position" do
        append(stream, 4, ExpectedVersion.any)
        retain(stream, max_count: 1)

        expect(plan(stream).to_mark).to eq(3)
      end

      specify "max_count does not count the tombstone sentinel" do
        append(stream, 3)
        tombstone(stream)
        retain(stream, max_count: 2)

        expect(plan(stream).to_mark).to eq(1)
      end

      specify "hides entries linked before now - max_age" do
        old = append(stream, 2)
        cutoff = Time.now.utc
        sleep(0.01)
        append(stream, 1)
        retain(stream, max_age: 60)

        plan = plan(stream, now: cutoff + 60)

        expect(plan.reasons).to eq([:max_age])
        expect(plan.to_mark).to eq(old.size)
      end

      specify "max_age hides nothing that is younger" do
        append(stream, 2)
        retain(stream, max_age: 60)

        expect(plan(stream)).to be_empty
        expect(plan(stream).reasons).to eq([])
      end

      specify "max_age counts from link time, not from the event's timestamp" do
        append(stream, 2, timestamp: Time.utc(2000, 1, 1))
        retain(stream, max_age: 60)

        expect(plan(stream)).to be_empty
      end

      specify "max_age hides every entry once all are old enough" do
        append(stream, 3)
        retain(stream, max_age: 60)

        expect(plan(stream, now: far_future).to_mark).to eq(3)
      end

      specify "the boundary is the furthest of the rules" do
        append(stream, 6)
        truncate(stream, 1)
        retain(stream, max_count: 2, max_age: 60)

        plan = plan(stream, now: far_future)

        expect(plan.reasons).to eq(%i[truncate_before max_count max_age])
        expect(plan.to_mark).to eq(6)
        expect(plan(stream).to_mark).to eq(4)
        expect(plan(stream).reasons).to eq(%i[truncate_before max_count])
      end

      specify "the furthest boundary wins whichever rule sets it" do
        append(stream, 5)
        truncate(stream, 4)
        retain(stream, max_count: 3)

        plan = plan(stream)

        expect(plan.reasons).to eq(%i[truncate_before max_count])
        expect(plan.to_mark).to eq(4)
      end

      specify "a tombstone hides nothing" do
        append(stream, 3)
        tombstone(stream)

        expect(plan(stream)).to be_empty
        expect(plan(stream, sweep_before: far_future)).to be_empty
        expect(plan(stream).reasons).to eq([])
      end

      specify "counts entries hidden before sweep_before" do
        append(stream, 4)
        truncate(stream, 3)
        mark_truncated(stream)

        expect(plan(stream, sweep_before: far_future).to_sweep).to eq(3)
        expect(plan(stream, sweep_before: Time.now.utc - 3600).to_sweep).to eq(0)
      end

      specify "never counts the position anchor to sweep" do
        append(stream, 3)
        soft_delete(stream)
        mark_truncated(stream)

        expect(plan(stream, sweep_before: far_future).to_sweep).to eq(2)
      end

      specify "never counts the tombstone sentinel to sweep" do
        append(stream, 3)
        tombstone(stream)
        soft_delete(stream)
        mark_truncated(stream)

        expect(plan(stream, sweep_before: far_future).to_sweep).to eq(3)
      end

      specify "plans only the given stream" do
        append(stream, 3)
        append(other_stream, 3)
        soft_delete(other_stream)
        mark_truncated(other_stream)

        expect(plan(stream, sweep_before: far_future)).to be_empty
      end

      specify "changes nothing" do
        append(stream, 5)
        truncate(stream, 2)
        retain(stream, max_count: 1)

        plan(stream, now: far_future, sweep_before: far_future)

        expect(read_ids(stream).size).to eq(5)
      end
    end

    describe "mark" do
      specify "hides entries up to the boundary in batches, oldest first" do
        event_ids = append(stream, 5)
        retain(stream, max_count: 1)
        plan = plan(stream)

        expect(strategy.mark(plan, 2, now: Time.now.utc)).to eq(2)
        expect(read_ids(stream)).to eq(event_ids.drop(2))
        expect(strategy.mark(plan, 2, now: Time.now.utc)).to eq(2)
        expect(read_ids(stream)).to eq(event_ids.drop(4))
        expect(strategy.mark(plan, 2, now: Time.now.utc)).to eq(0)
        expect(read_ids(stream)).to eq(event_ids.drop(4))
      end

      specify "is idempotent" do
        append(stream, 3)
        retain(stream, max_count: 1)
        plan = plan(stream)

        expect(strategy.mark(plan, 10, now: Time.now.utc)).to eq(2)
        expect(strategy.mark(plan, 10, now: Time.now.utc)).to eq(0)
        expect(mark(stream)).to eq(0)
      end

      specify "marks nothing without a boundary" do
        append(stream, 3)
        retain(stream, max_count: 5)

        expect(strategy.mark(plan(stream), 10, now: Time.now.utc)).to eq(0)
        expect(read_ids(stream).size).to eq(3)
      end

      specify "finishes a truncation" do
        event_ids = append(stream, 5)
        truncate(stream, 3)

        expect(mark(stream)).to eq(3)
        expect(read_ids(stream)).to eq(event_ids.drop(3))
      end

      specify "keeps entries appended after the plan visible" do
        append(stream, 3)
        retain(stream, max_count: 1)
        plan = plan(stream)
        fresh = append(stream, 2)

        strategy.mark(plan, 10, now: Time.now.utc)

        expect(read_ids(stream).last(2)).to eq(fresh)
        expect(read_ids(stream).size).to eq(3)
      end

      specify "keeps entries appended after delete_stream visible" do
        append(stream, 3)
        soft_delete(stream)
        plan = plan(stream)
        repository.delete_stream(stream)
        fresh = append(stream, 2)

        strategy.mark(plan, 10, now: Time.now.utc)

        expect(read_ids(stream)).to eq(fresh)
      end

      specify "marks only the planned stream" do
        append(stream, 3)
        other = append(other_stream, 3)
        retain(stream, max_count: 1)
        retain(other_stream, max_count: 1)

        mark(stream)

        expect(read_ids(stream).size).to eq(1)
        expect(read_ids(other_stream)).to eq(other)
      end

      specify "keeps the events in the global stream" do
        event_ids = append(stream, 3)
        retain(stream, max_count: 1)

        mark(stream)

        expect(global_ids).to include(*event_ids)
      end

      specify "a restore shows marked entries again" do
        event_ids = append(stream, 3)
        retain(stream, max_count: 1)
        mark(stream)

        restore(stream)

        expect(read_ids(stream)).to eq(event_ids)
      end

      specify "marks at the given time" do
        append(stream, 3)
        retain(stream, max_count: 1)
        marked_at = Time.now.utc.round(TIMESTAMP_PRECISION) - 3600

        mark(stream, now: marked_at)

        expect(strategy.sweep(stream, 10, before: marked_at)).to eq(0)
        expect(strategy.sweep(stream, 10, before: marked_at + 1)).to eq(2)
      end
    end

    describe "sweep" do
      specify "removes entries marked before the cutoff in batches" do
        append(stream, 6)
        retain(stream, max_count: 1)
        mark(stream)

        expect(strategy.sweep(stream, 2, before: far_future)).to eq(2)
        expect(plan(stream, sweep_before: far_future).to_sweep).to eq(3)
        expect(strategy.sweep(stream, 2, before: far_future)).to eq(2)
        expect(strategy.sweep(stream, 2, before: far_future)).to eq(1)
        expect(strategy.sweep(stream, 2, before: far_future)).to eq(0)
      end

      specify "removes the oldest first" do
        event_ids = append(stream, 4)
        retain(stream, max_count: 1)
        mark(stream)
        strategy.sweep(stream, 2, before: far_future)

        restore(stream)

        expect(read_ids(stream)).to eq(event_ids.drop(2))
      end

      specify "removes nothing marked at or after the cutoff" do
        append(stream, 3)
        retain(stream, max_count: 1)
        marked_at = Time.now.utc.round(TIMESTAMP_PRECISION)
        mark(stream, now: marked_at)

        expect(sweep(stream, before: marked_at)).to eq(0)
        expect(sweep(stream, before: marked_at - 3600)).to eq(0)
        expect(plan(stream, sweep_before: marked_at).to_sweep).to eq(0)
      end

      specify "never removes a visible entry" do
        event_ids = append(stream, 3)
        retain(stream, max_count: 5)

        expect(sweep(stream)).to eq(0)
        expect(read_ids(stream)).to eq(event_ids)
      end

      specify "never removes an entry shown again by restore" do
        event_ids = append(stream, 3)
        retain(stream, max_count: 1)
        mark(stream)
        write(StreamMetadataEvents::StreamMetadataChanged, stream, max_count: nil, max_age: nil)
        restore(stream)

        expect(sweep(stream)).to eq(0)
        expect(read_ids(stream)).to eq(event_ids)
      end

      specify "keeps the position anchor" do
        event_ids = append(stream, 3)
        soft_delete(stream)
        mark_truncated(stream)

        expect(sweep(stream)).to eq(2)
        expect(last_version_and_tombstone(stream)).to eq([2, false])

        restore(stream)
        expect(read_ids(stream)).to eq(event_ids.last(1))
      end

      specify "continues positions after a full sweep" do
        append(stream, 3)
        soft_delete(stream)
        mark_truncated(stream)
        sweep(stream)

        fresh = append(stream, 1)

        expect(repository.position_in_stream(fresh.first, stream)).to eq(3)
      end

      specify "keeps the newest entry when entries have no position" do
        event_ids = append(stream, 3, ExpectedVersion.any)
        soft_delete(stream)
        mark_truncated(stream)

        expect(sweep(stream)).to eq(2)

        restore(stream)
        expect(read_ids(stream)).to eq(event_ids.last(1))
      end

      specify "keeps the tombstone sentinel" do
        append(stream, 3)
        tombstone(stream)
        soft_delete(stream)
        mark_truncated(stream)

        expect(sweep(stream)).to eq(3)
        expect(last_version_and_tombstone(stream)).to eq([3, true])

        restore(stream)
        expect(read_ids(stream)).to eq([])
        expect { append(stream, 1, ExpectedVersion.new(2)) }.to raise_error(WrongExpectedEventVersion)
      end

      specify "keeps the tombstone sentinel when entries follow it" do
        append(stream, 3)
        tombstone(stream)
        append(stream, 2)
        soft_delete(stream)
        mark_truncated(stream)

        expect(sweep(stream)).to eq(4)
        expect(last_version_and_tombstone(stream)).to eq([5, true])
      end

      specify "keeps the tombstone sentinel of an empty stream" do
        tombstone(stream)

        expect(sweep(stream)).to eq(0)
        expect(last_version_and_tombstone(stream)).to eq([0, true])
      end

      specify "removes only links, the events stay" do
        event_ids = append(stream, 3)
        retain(stream, max_count: 1)
        mark(stream)

        sweep(stream)

        expect(global_ids).to include(*event_ids)
        event_ids.each { |event_id| expect(repository.has_event?(event_id)).to be(true) }
      end

      specify "sweeps only the given stream" do
        append(stream, 3)
        append(other_stream, 3)
        retain(stream, max_count: 1)
        retain(other_stream, max_count: 1)
        mark(stream)
        mark(other_stream)

        expect(sweep(stream)).to eq(2)
        expect(plan(other_stream, sweep_before: far_future).to_sweep).to eq(2)
      end

      specify "is idempotent" do
        append(stream, 3)
        retain(stream, max_count: 1)
        mark(stream)

        expect(sweep(stream)).to eq(2)
        expect(sweep(stream)).to eq(0)
      end

      specify "sweeps an entry once hidden by truncate_stream" do
        append(stream, 3)
        truncate(stream, 2)
        mark_truncated(stream)

        expect(sweep(stream)).to eq(2)
      end
    end
  end
end
