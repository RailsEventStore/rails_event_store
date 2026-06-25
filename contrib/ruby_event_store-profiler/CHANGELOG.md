### 0.2.0

- Change: Allow `ruby_event_store` 3.x by relaxing the dependency bound to `< 4.0`.
- Change: Match the renamed `*.ruby_event_store` instrumentation events (the `METRICS` regex was `rails_event_store`), so the profiler captures RubyEventStore 3.0 events.
- Change: README example uses `RubyEventStore::SyncScheduler` (`RubyEventStore::Dispatcher` was removed in RES 3.0).

### 0.1.0

- Initial release
