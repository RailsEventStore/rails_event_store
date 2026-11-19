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
stopped), `--throttle SECONDS` (sleep between batches), `--stream NAME` (repeatable).

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

## What it never removes

- an entry before it was hidden for the whole grace period;
- the position anchor: the entry with the highest position of a stream (the newest one when
  entries have no position), so the last stream version, and with it the numbering of later
  appends, survives a full sweep;
- the sentinel of a tombstoned stream;
- events: only their links to the stream.

Until SWEEP, `restore_stream` shows hidden entries again.

## Status and locking

`res-scavenge status` prints `idle`, `marking` or `sweeping`, the stream being worked on, the
cursor (the last stream finished) and the time of the record. One run at a time: an advisory
lock on PostgreSQL, `GET_LOCK` on MySQL, the status row elsewhere (taken over after an hour).
A run that finds the lock taken exits with status 0 and does nothing.

## Instrumentation

`scavenge.ruby_event_store` (policy, dry_run, report), `scavenge_stream.ruby_event_store`
(stream, reasons, dry_run, marked, swept), `scavenge_batch.ruby_event_store` (stream, phase,
size).
