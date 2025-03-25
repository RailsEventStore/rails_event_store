### 0.0.29  2025-03-25

* Fix an issue with uninitialized constant `RubyEventStore::Outbox::RetriableError` when using `bin/res_outbox`

### 0.0.28  2024-04-12

* Fix issues that prevent res_outbox CLI from processing
* Upgrade docker image base to ruby:3.2

### 0.0.27  2024-04-12

* Fix issues that prevent res_outbox CLI from starting

### 0.0.26  2024-04-12

* stop testing with sidekiq 5, start testing with sidekiq 7
* get rid of deprecation warnings from sidekiq 7
* predictable redis failures (like timeout errors) are now retried (once) instead of being treated like any other error (being logged)
* instead of immediately starting with processing full batch size, exponential progress is implemented so that big messages OOMing the infrastructure can be pushed through

### 0.0.25  2022-05-27

* added ORDER BY when cleaning up with limit #1338

### 0.0.24

* fixed error with passing `--cleanup-limit` from CLI down to consumer
* added missing specs for CLI options
* added simple smoke spec to ensure CLI builds consumer without errors
* dropped support for rails 5.2
* dropped support for ruby 2.6

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
