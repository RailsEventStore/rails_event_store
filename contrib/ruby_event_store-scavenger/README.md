# RubyEventStore Scavenger

Physical removal of hidden stream entries, as a process apart from your application.

Stream retention (`set_stream_metadata` with `max_count` / `max_age`), `truncate_stream` and
`soft_delete_stream` only change what reads of a stream return. The scavenger turns that into
storage: it hides what retention says should be hidden (MARK) and deletes the links of entries
hidden for longer than a grace period (SWEEP). With the `links_only` policy the events stay in
the global stream, so global positions have no gaps.

The gem is not a dependency of `rails_event_store`. Add it only where the scavenger runs.

## Setup

Requires the ActiveRecord repository with the native truncation migrations
(`db:migrations:add_truncated_at`, `db:migrations:add_streams_metadata`) and one more table for
the scavenger's status and lock:

```
bin/rails generate ruby_event_store:scavenger:migration
# or, outside Rails
bundle exec rake res:scavenge:migration MIGRATION_PATH=db/migrate
```

## Running

```
res-scavenge --database-url $DATABASE_URL --serializer json            # dry run: report only
res-scavenge --database-url $DATABASE_URL --serializer json --execute  # mark and sweep
res-scavenge --database-url $DATABASE_URL status
```

A dry run is the default: it changes nothing, takes no lock and writes no status. Pass the
serializer your event store uses (`yaml` by default, `json`): the scavenger appends
`StreamScavenged` to the meta stream of each stream it removed links from.

Options: `--grace-period SECONDS` (7 days by default; shorter only with `--force`),
`--batch-size N` (1000), `--max-duration SECONDS` (300; the next run resumes where this one
stopped), `--throttle SECONDS` (sleep between batches), `--stream NAME` (repeatable),
`--policy NAME` (`links_only` by default, or `purge`, see below).

In a Rails application:

```
bundle exec rake res:scavenge                    # dry run
bundle exec rake res:scavenge EXECUTE=1 SERIALIZER=json
bundle exec rake res:scavenge:status
```

or as a job, performed by a worker of its own with `RES_SCAVENGER` set in its environment:

```ruby
RubyEventStore::Scavenger::Job.perform_later(execute: true, serializer: "json")
```

From Ruby:

```ruby
RubyEventStore::Scavenger::Runner
  .active_record(serializer: JSON, batch_size: 1_000, throttle: 0.05)
  .call(dry_run: false)
```

`Runner#call` raises `NotAllowed` unless `RES_SCAVENGER` is set in the environment or
`allow_in_process: true` is passed, so an application that loads the gem by accident does not
delete data. The command line and the rake task pass `allow_in_process: true`.

Run it as a process, pod or dyno of its own (a cron job, a systemd timer, a scheduler), not in
an application worker. Frequent runs (minutes) keep retention close to its settings: until a
run marks them, entries past `max_count` / `max_age` are still read.

## Policy purge

**`purge` DELETES EVENTS AND LEAVES GAPS IN GLOBAL POSITIONS.** Projections, catch-up
subscriptions and anything else that reads the global stream by position may not expect a
missing event. Prefer encryption with a forgotten key and `update_messages`, or `max_age`
retention with `links_only`, where they do the job; `purge` is the last resort, for data that
has to go from storage. Take a verified backup before the first `purge` run.

With `purge`, SWEEP removes the links as `links_only` does and then, in the same transaction,
every event of a removed link that no stream links to any more (checked per event). Links go
first, so the foreign key from `event_store_events_in_streams.event_id` to
`event_store_events`, where the schema has it, holds. The same grace period and `--force`
rules apply, and a dry run is still the default: it reports how many events a run would remove.

The policy needs an explicit confirmation, or the runner raises `PurgeNotConfirmed`:

```
res-scavenge --database-url $DATABASE_URL --serializer json \
             --policy purge --i-understand-global-position-gaps             # dry run
res-scavenge --database-url $DATABASE_URL --serializer json \
             --policy purge --i-understand-global-position-gaps --execute   # removes events
bundle exec rake res:scavenge POLICY=purge I_UNDERSTAND_GLOBAL_POSITION_GAPS=1 EXECUTE=1
```

```ruby
RubyEventStore::Scavenger::Runner
  .active_record(serializer: JSON, policy: :purge, confirm: :i_understand_global_position_gaps)
  .call(dry_run: false)
```

An event linked to several streams lives as long as its longest kept link: it goes with the
last of its links. Only events of links a `purge` run removes itself go; an event whose last
link was removed earlier (by `links_only` or `delete_stream`), or that was never linked to a
stream, stays. A dry run counts, per stream, the events no other stream links to, so an event
linked from several streams that are all due to be swept is counted for none of them. Without
the foreign key, an event linked to a stream in the very moment `purge` removes it can leave
a link to a missing event; with the foreign key that link is refused.

`purge` never removes the event of the position anchor (its link stays), the tombstone
sentinel's event, or the metadata events in the `$$` meta streams.

## What it never removes

- an entry before it was hidden for the whole grace period;
- the position anchor: the entry with the highest position of a stream (the newest one when
  entries have no position), so the last stream version, and with it the numbering of later
  appends, survives a full sweep;
- the sentinel of a tombstoned stream;
- events: only their links to the stream (with the default `links_only` policy).

Until SWEEP, `restore_stream` shows hidden entries again.

## Status and locking

`res-scavenge status` prints `idle`, `marking`, `sweeping` or `purging`, the stream being
worked on, the cursor (the last stream finished) and the time of the record. One run at a time:
an advisory lock on PostgreSQL, `GET_LOCK` on MySQL, the status row elsewhere (taken over after an hour).
A run that finds the lock taken exits with status 0 and does nothing.

## Instrumentation

`scavenge.ruby_event_store` (policy, dry_run, report), `scavenge_stream.ruby_event_store`
(stream, reasons, dry_run, marked, swept, purged), `scavenge_batch.ruby_event_store` (stream,
phase: `mark`, `sweep` or `purge`, size: entries marked or links removed).
