### unreleased

### 0.0.25

* added ORDER BY when cleaning up with limit #1338

### 0.0.24

* fixed error with passing `--cleanup-limit` from CLI down to consumer
* added missing specs for CLI options
* added simple smoke spec to ensure CLI builds consumer without errors

### 0.0.23

- add --cleanup-limit CLI option which allows to set
  Amount of records removed in single cleanup run.
  It's default value is `:all` for backward compatibility

### 0.0.22

- make it work with sidekiq 6.4.2

### 0.0.21

- added support for rails 7.0
- added support for specifying `retry_queue` for scheduled jobs
- get rid of depracation warnings from sidekiq 6.4.1

### 0.0.20

- Fixed problem with missing constant `SIDEKIQ5_FORMAT`

### 0.0.19

- `RubyEventStore::Outbox::SidekiqScheduler` which works for RES 1.x will is now called `RubyEventStore::Outbox::LegacySidekiqScheduler`
- `RubyEventStore::Outbox::SidekiqScheduler` is now a scheduler for RES 2.x
