---
title: Stream deletion and retention
sidebar_label: Stream deletion and retention
---

[`delete_stream`](./delete) removes all links of a stream at once and cannot be undone. This page describes the finer tools: hiding a part of a stream or the whole stream from reads (and showing it again), closing a stream for writes, limiting how much a stream keeps, and physically removing what is no longer needed.

The tools are separate on purpose:

- **tombstone** decides who may write: a tombstoned stream refuses `append` and `link`,
- **truncate** and **soft delete** decide what reads see,
- the **scavenger** removes hidden entries from the database, in a process of its own.

None of them touches events themselves: an event stays in the global stream (and in the other streams it is linked to) until you explicitly choose otherwise.

All of this is opt-in. Without the decorator described below nothing changes, no code from this page is executed and `delete_stream` behaves as it always did.

## Enabling it

Wrap the repository with `RubyEventStore::StreamMetadataAwareRepository`:

```ruby
Rails.configuration.event_store = RailsEventStore::Client.new(
  repository: RubyEventStore::StreamMetadataAwareRepository.new(
    RubyEventStore::ActiveRecord::EventRepository.new(serializer: RubyEventStore::Serializers::YAML)
  )
)
```

Options of the decorator:

- `batch_size` (default `1000`): number of entries hidden or shown per transaction by `truncate_stream`, `soft_delete_stream` and `restore_stream`.
- `publish_metadata_events` (default `false`): see [Metadata events](#metadata-events).

The repository has to support hiding entries natively: `RubyEventStore::InMemoryRepository` does, and so does the ActiveRecord repository once the [migrations](#migrations) are applied. On a repository without native support `truncate_stream`, `soft_delete_stream` and `restore_stream` raise `RubyEventStore::StreamMetadataNotSupported`, while retention settings and tombstones still work.

## Client API

```ruby
client.set_stream_metadata("sensor_readings", max_count: 10_000, max_age: 30 * 24 * 3600)
client.stream_metadata("sensor_readings")
# => #<data RubyEventStore::StreamMetadata max_count=10000, max_age=2592000, truncate_before=nil, tombstoned_at=nil, soft_deleted_at=nil>

client.truncate_stream("sensor_readings", before: 500)  # hides entries at positions 0..499
client.soft_delete_stream("sensor_readings")            # hides every entry the stream holds
client.restore_stream("sensor_readings")                # shows hidden entries again
client.tombstone_stream("sensor_readings")              # no more appends or links
```

Every method takes `expected_version:` (default `:any`), which refers to the version of the stream's own history of metadata changes, not to the version of the stream being described. Pass `:auto`, `:none` or an Integer to make concurrent administrative calls safe.

- **`set_stream_metadata(stream, max_count:, max_age:)`** sets both retention settings at once; `nil` clears one. Values have to be positive Integers, otherwise `InvalidStreamMetadata` is raised. `max_age` is in seconds. See [Retention](#retention).
- **`stream_metadata(stream)`** returns the current state as `RubyEventStore::StreamMetadata`. It has predicates `tombstoned?`, `soft_deleted?`, `deleted?` (either of the two) and `retention?`.
- **`truncate_stream(stream, before:)`** hides entries at positions below `before`. The boundary never moves back. `before:` is an Integer position.
- **`soft_delete_stream(stream)`** hides every entry the stream holds at that moment.
- **`restore_stream(stream)`** shows hidden entries again, as long as the scavenger did not remove them yet. It returns a `StreamRestore` with `restored` (entries shown again) and `missing` (entries already removed by the scavenger).
- **`tombstone_stream(stream)`** closes the stream for writes for good. Raises `StreamTombstoned` when the stream is already tombstoned.

Marking entries as hidden happens in the calling process: the event recording the intent is written first, then entries are hidden oldest first in batches of `batch_size`, each in its own transaction, and the call returns after the last batch. Readers see a prefix of the stream shrinking, never a gap in the middle. A call that was interrupted leaves the intent recorded: repeat it, or let the scavenger finish it.

## What reads see

A hidden entry behaves as if it was not in the stream:

- `read.stream("name")` leaves it out **before** `limit`, batches, `first` / `last`, `count`, `from` / `to` and time-sorted reads are applied, so every query described in [Reading events](./read) works unchanged on a truncated stream,
- `event_in_stream?` returns `false`, `position_in_stream` raises `EventNotFoundInStream` and `streams_of` leaves the stream out,
- the global stream is not affected: the events are still there.

**Positions stay continuous.** Hiding never renumbers anything, and neither does the scavenger: the entry with the highest position of a stream is never removed. The last stream version, and with it the numbering of later appends, survives a soft delete and a full sweep. A stream name is therefore never reused by accident: after a soft delete a new append gets the next position, not position 0.

**Appending after a soft delete is allowed.** New entries continue the numbering, are visible, and the older ones stay hidden. It does not undo the soft delete; `restore_stream` does.

**Tombstone blocks writes only.** `read.stream` and everything else sees the full history of a tombstoned stream. What may still be done to such a stream is whatever only changes visibility: `truncate_stream`, `soft_delete_stream`, `restore_stream` and retention settings. For "close and hide" combine `tombstone_stream` with `soft_delete_stream`. The tombstone itself is stored as a hidden entry at the position after the last one; `restore_stream` never shows it and the scavenger never removes it.

Concurrent appends to a stream being tombstoned are handled by the unique index on `(stream, position)`: an append with `:auto`, an Integer or `:none` raises `WrongExpectedEventVersion` and, once retried, `StreamTombstoned`. An append or `link` with `expected_version: :any` is checked best-effort: a write racing with `tombstone_stream` may still get through. This is part of what `:any` means.

### `delete_stream` with the decorator

`delete_stream` is unchanged, with two differences once the decorator is on:

- on a truncated or soft deleted stream it appends `StreamRestored` afterwards, so the metadata does not describe entries that are gone,
- on a tombstoned stream it raises `StreamTombstoned`.

## Metadata events

Every change above is recorded as an event in a stream named `$$` plus the name of the stream it describes (`$$sensor_readings`):

- `StreamMetadataChanged` (`max_count`, `max_age`)
- `StreamTruncated` (`before_position`)
- `StreamSoftDeleted`
- `StreamRestored`
- `StreamTombstoned`
- `StreamScavenged` (written by the scavenger: policy and the number of removed links)

They are appended, not published, so subscribers do not see them and nothing can react to them in the middle of the operation. They carry the metadata of the client's enrichment (correlation id, request metadata) the same as published events do. Pass `publish_metadata_events: true` to the decorator to publish them as well, once the operation is complete. Mind a handler that writes to the stream in reaction.

The `$$` streams are the audit trail of administrative actions on a stream: who, when, how.

### Reserved names

Stream names starting with `$` are reserved by the decorator and cannot be appended to or linked to by your code. An application that already has streams starting with `$` cannot append to them once the decorator is on. The prefix is not configurable.

## Retention

```ruby
client.set_stream_metadata("sensor_readings", max_count: 10_000, max_age: 7 * 24 * 3600)
```

- `max_count`: the stream keeps this many of the newest entries.
- `max_age`: the stream keeps an entry for this many seconds after it **entered the stream**.

Nothing is enforced at read time. Setting retention only records the intent; the [scavenger](#scavenger) enforces it, and until its next run the entries past the limits are still read. **Retention is an approximation: the staleness window equals the interval between scavenger runs.** For streams with retention run the scavenger often, every few minutes. A reader that needs exact age filtering should use `newer_than` in its own [specification](./read).

In exchange, reads do not pay for retention: no extra queries, no joins.

Things to know:

- **`max_age` counts from link time**, the time the entry was added to the stream (the `created_at` of the row in `event_store_events_in_streams`), not from the event's `timestamp` or `valid_at`. An event published with a back-dated `timestamp` (an import, a migration) does not escape retention, and a freshly linked old event is not swept at once.
- `max_count` counts entries (links), not unique events.
- **Not recommended for streams read bi-temporally.** Retention runs on link time, while a read with `valid_at` or `read.as_of` rebuilds state from business time. Removing an old entry can drop an event whose `valid_at` is still needed (a back-dated correction, an event valid in the future), and the reconstructed state changes silently. See [bi-temporal](../advanced-topics/bi-temporal).

## Limits and warnings

- **Do not use truncate, soft delete or retention on aggregate streams.** [`AggregateRoot`](./event-sourcing) takes the expected version of the next write from the number of events it read. After any hiding of entries that number is too low and every later `store` raises `WrongExpectedEventVersion`, for good. Closing an aggregate is a job for a tombstone.
- `truncate_stream(before:)` works on positions, so it **does not hide entries without a position**: those linked or appended with `expected_version: :any`. `soft_delete_stream` hides them.
- **MySQL: stream names longer than 253 characters cannot have metadata.** The name of the metadata stream, `$$` plus the name, has to fit in the 255 characters of the `stream` column.
- **`restore_stream` also shows entries hidden by retention**, until the next scavenger run hides them again.
- Hiding is cheap, removing is not undoable: before the first `:purge` (see below) take a **verified backup**, and keep in mind that a dump taken while the scavenger sweeps is a dump of a moving target.
- Users' own SQL that orders a stream by `id` without `truncated_at IS NULL` no longer finds an index on PostgreSQL and SQLite after the migration; see below.

## Migrations

The ActiveRecord repository needs two migrations. Without them reads, writes and SQL stay exactly as they were.

```
bin/rails generate ruby_event_store:active_record:migration_for_truncated_at
bin/rails generate ruby_event_store:active_record:migration_for_streams_metadata
# or, without the generators
bundle exec rake db:migrations:add_truncated_at
bundle exec rake db:migrations:add_streams_metadata
```

- `add_truncated_at` adds the `truncated_at` column to `event_store_events_in_streams`.
- `add_streams_metadata` creates `event_store_streams_metadata`, one row per stream with metadata.

The generated files belong to your application and use the syntax of your database.

### PostgreSQL

The migration adds the column and replaces the index on `(stream, id)` with a **partial index** on the visible entries (`WHERE truncated_at IS NULL`), in two steps, both concurrent so they do not lock writes:

1. `CREATE INDEX CONCURRENTLY` the partial index `index_event_store_events_in_streams_on_stream_and_id_visible`,
2. `DROP INDEX CONCURRENTLY` the old index.

The order matters: reads of a stream are served by an index at every moment. The migration disables the DDL transaction because concurrent index operations cannot run in one.

**A concurrent index build that fails leaves an `INVALID` index behind.** If the migration stops in the middle, find it and drop it by hand before running the migration again:

```sql
SELECT indexrelid::regclass FROM pg_index WHERE NOT indisvalid;
DROP INDEX CONCURRENTLY index_event_store_events_in_streams_on_stream_and_id_visible;
```

Reads of a stream use the new index only once it exists: until then (and on a database without the migration) the repository does not filter, so a rollout is safe in any order. The repository checks for the index once per process, at the first read, so restart processes after migrating.

SQLite works the same way, without the concurrency.

### MySQL

MySQL has no partial indexes, so the migration only adds the column and the existing index stays. Reads skip hidden entries while scanning it: **the more entries are hidden and not yet removed, the more rows every read of that stream goes through.** The cost grows with the hidden prefix and disappears when the scavenger sweeps it. Run the scavenger frequently and consider a shorter grace period there (see [Scavenger](#scavenger)); it is a conscious trade-off between the read cost and the time in which `restore_stream` is possible.

## Scavenger

Retention, `truncate_stream` and `soft_delete_stream` only change what reads return. Physical removal is done by a separate gem, `ruby_event_store-scavenger`, which is deliberately not a dependency of `rails_event_store`: add it only where the scavenger runs.

```ruby
# Gemfile of the scavenger's deployment
gem "ruby_event_store-scavenger"
```

It needs one more table for its status and lock:

```
bin/rails generate ruby_event_store:scavenger:migration
# or, outside Rails
bundle exec rake res:scavenge:migration MIGRATION_PATH=db/migrate
```

A run does two things for each stream that has metadata:

1. **MARK** hides what retention says should be hidden: entries past `max_count` or older than `max_age`.
2. **SWEEP** removes the links of entries that were hidden **longer ago than the grace period**.

With the `links_only` policy only the links to the stream are removed. The events stay in the global stream, so global positions have no gaps and projections keep working.

It never removes:

- an entry hidden for less than the grace period,
- the entry with the highest position of a stream (the newest one for entries without positions): the position anchor,
- the tombstone,
- events (with `links_only`; see `purge` below).

### Running it

```
res-scavenge --database-url $DATABASE_URL --serializer json            # dry run: reports only
res-scavenge --database-url $DATABASE_URL --serializer json --execute  # mark and sweep
res-scavenge --database-url $DATABASE_URL status
```

**A dry run is the default.** Nothing is changed, locked or recorded unless you pass `--execute`. The report says how many entries each stream would have marked and swept right now.

Options:

| Option | Default | |
| --- | --- | --- |
| `--grace-period SECONDS` | 7 days | Sweep only entries hidden longer ago. A shorter period needs `--force`. |
| `--force` | | Allow a grace period shorter than 7 days. |
| `--batch-size N` | 1000 | Entries per batch. |
| `--max-duration SECONDS` | 300 | Stop cleanly after this long; the next run resumes where this one stopped. |
| `--throttle SECONDS` | 0 | Sleep between batches. |
| `--stream NAME` | all | Only this stream; can be repeated. |
| `--policy NAME` | `links_only` | `links_only` or `purge`. |
| `--i-understand-global-position-gaps` | | Required by `--policy purge`. |
| `--serializer NAME` | `yaml` | `yaml` or `json`: the serializer of your event store. |

The grace period is the window in which a mistake can be undone with `restore_stream`. It also applies to retention: entries marked by `max_count` or `max_age` are removed after the grace period, not at once. On MySQL a longer grace period means a longer read degradation (see above).

`res-scavenge status` prints where the last run is: `idle`, `marking`, `sweeping` or `purging`, the stream it works on, the cursor (the last stream finished) and the time of the record. Only one run goes at a time (an advisory lock on PostgreSQL, `GET_LOCK` on MySQL); a run that finds the lock taken exits and does nothing.

In a Rails application the same is available as a rake task and as a job:

```
bundle exec rake res:scavenge                       # dry run
bundle exec rake res:scavenge EXECUTE=1 SERIALIZER=json
bundle exec rake res:scavenge:status
```

```ruby
RubyEventStore::Scavenger::Job.perform_later(execute: true, serializer: "json")
```

From Ruby: `RubyEventStore::Scavenger::Runner.active_record(serializer: JSON).call(dry_run: false)`.

### Deployment

**Run the scavenger as a process of its own**: a cron job, a systemd timer, a scheduled task, a separate pod or dyno. Not inside the web application and not in a worker that also performs your jobs. `Runner#call` raises `NotAllowed` unless `RES_SCAVENGER` is set in the environment (the command line and the rake task set it for you), so an application that loads the gem by accident does not remove data. A job performed by the scavenger needs a worker of its own with `RES_SCAVENGER` set, on a queue no other worker takes.

Schedule it as often as the staleness you can accept for retention (minutes is reasonable). A run with nothing to do is cheap.

The scavenger reports through `ActiveSupport::Notifications`: `scavenge.ruby_event_store`, `scavenge_stream.ruby_event_store` and `scavenge_batch.ruby_event_store`.

### Removing events: `:purge`

The `purge` policy deletes events. **It leaves gaps in global positions**: projections and catch-up subscriptions that read the global stream by position may break on them. Use it as the last resort, for data that has to go from storage, after encryption with `update_messages` and after `max_age` with `links_only`. Take a **verified backup** before the first `purge` run.

With `purge`, SWEEP removes the links as `links_only` does and then, in the same transaction for each batch, deletes every event of a removed link that no stream links to any more. Links go first and events second, so the foreign key from `event_store_events_in_streams.event_id` to `event_store_events` holds. Without that foreign key, a link inserted at the very moment `purge` removes its event can be left pointing at a missing event; with it the insert is refused.

The policy needs an explicit confirmation. Without exactly the symbol `:i_understand_global_position_gaps` (a string does not count) the runner raises `RubyEventStore::Scavenger::PurgeNotConfirmed`, a dry run included:

```
res-scavenge --database-url $DATABASE_URL --serializer json \
             --policy purge --i-understand-global-position-gaps             # dry run
res-scavenge --database-url $DATABASE_URL --serializer json \
             --policy purge --i-understand-global-position-gaps --execute   # removes events

bundle exec rake res:scavenge POLICY=purge I_UNDERSTAND_GLOBAL_POSITION_GAPS=1 EXECUTE=1 SERIALIZER=json
```

```ruby
RubyEventStore::Scavenger::Runner
  .active_record(serializer: JSON, policy: :purge, confirm: :i_understand_global_position_gaps)
  .call(dry_run: false)

RubyEventStore::Scavenger::Job.perform_later(
  policy: "purge", confirm: :i_understand_global_position_gaps, execute: true, serializer: "json"
)
```

The dry run is still the default and reports `to purge N` for each stream. The grace period (7 days) and `--force` work as for SWEEP.

What gets purged and what does not:

- Only events of links that this very run removes, and only once no link to them is left. An event linked into several streams lives as long as its longest-kept link.
- Never purged: the event of the position anchor, the event of the tombstone, metadata events in `$$` streams, events still linked from any stream, events whose last link was removed earlier (by `links_only` or `delete_stream`: switching to `purge` later does not collect them) and events never linked to any stream (appended to the global stream only).
- The dry run counts per stream, so an event linked from several streams that are all due to be swept counts for none of them. The real run removes it at the last of those streams.

`StreamScavenged` records the number of removed events in `removed_events`. While purging, `res-scavenge status` prints `purging`. The notification `scavenge_stream.ruby_event_store` carries `purged`, and `scavenge_batch.ruby_event_store` has the phase `purge`.

## GDPR

Deletion tools complement, not replace, the approaches from [GDPR considerations](../advanced-topics/gdpr). Prefer them in this order:

1. **Encryption with a key you can forget** (cryptographic erasure), together with `update_messages` for data already stored. It leaves no gaps in global positions, does not need the scavenger and works backwards.
2. **`max_age`** for data that is supposed to expire anyway. It counts from the time an event entered a stream, so it is a time limit on streams, not "the event is gone after N days": an event linked into several streams is physically removed only when its last link is gone, so it lives as long as the longest-kept of its links. Remember the staleness window and the grace period.
3. **`:purge`**, the right to be forgotten when encryption was not used. The last resort, with full awareness of the gaps it leaves in global positions, and only after a verified backup.

Soft delete and `links_only` do not make data disappear from the database: the events remain. They are not a means of erasing personal data.
