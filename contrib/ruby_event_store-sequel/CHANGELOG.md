### 0.2.0

- Change: Allow `ruby_event_store` 3.x by relaxing the dependency bound to `< 4.0`.
- Change: Internal query optimizations in the Sequel event repository (global-stream select, `valid_at` handling). No schema change — existing tables are unaffected.

### 0.1.0

- Add: Initial repository implementation. Aimed as a SQL replacement for `ruby_event_store-active_record` repository. Useful for apps, that do not use ActiveRecord, i.e. Hanami.
