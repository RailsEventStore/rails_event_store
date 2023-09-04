### 2.2.0

- Change: Minimum required Ruby version is 2.7.0

- Add: Support for bi–temporal queries [#1674]

- Fix: Raise `RubyEventStore::EventNotFound` instead of `ROM::TupleCountMismatchError` if the `event_id` passed to `Specification#from` or `Specification#to` does not exist [#1673]

### 2.1.0

- Add: Support for Ruby 3.0 [59027ff8ad078e0948bbb190b8a6985c075dcc08]

- Add: Support for `event_in_stream?` queries [56ecdccfde5c2c794fcf01fa7ef396c18c558ec2]

  Read more: https://railseventstore.org/docs/v2/read/#position-of-an-event-in-the-stream

- Fix: Correct initialization for ROM to run migrations [#1262, a6accaf89c1fbeb172d0b5acf8c3fb9917328be6]

- Fix: Compatibility with Psych 4.x by introducing `RubyEventStore::Serializers::YAML` as default serializer  [7917bbd64238d2239294daec360dd9a1a4746ec2]

### 2.0.0

This release brings compatibility of `RubyEventStore::ROM::EventRepository` with RubyEventStore >= 2.0.

If you we're running RES in version 1.3.0 before, please check oua Ruby/RailsEventStore migration guide from 1.3.0 to 2.0.0 first:
https://github.com/RailsEventStore/rails_event_store/releases/tag/v2.0.0

- Fix: Updating messages via `RubyEventStore::Client#overwrite` with ROM repository no longer changes `created_at` column in the database.

  Given that `created_at` is now a source of a timestamp, you should consider overwriting timestamps from serialized metadata into `created_at` column if you have used `event_store.overwrite` in the past with ROM repository. If your serializer was YAML, this could be used to extract the timestamp in MySQL:

  ```
  SELECT STR_TO_DATE(SUBSTR(metadata, LOCATE(':timestamp: ', metadata) + 12, 31), '%Y-%m-%d %H:%i:%s.%f') FROM event_store_events;
  ```

- Fix: Timestamps changed to local time as Sequel expects. Those were previously put as UTC, which then was interpreted as a local time. Affects historical data. Mostly harmless if you acknowledge uniform time skew before certain point in time.

  If that drift is problematic to you, consider migrating the timestamp from `metadata` to `created_at`. If your serializer was YAML, this could be used to extract the timestamp in MySQL:

  ```
  SELECT STR_TO_DATE(SUBSTR(metadata, LOCATE(':timestamp: ', metadata) + 12, 31), '%Y-%m-%d %H:%i:%s.%f') FROM event_store_events;
  ```

- Change: Increase timestamp precision on MySQL and SQLite. Adds fractional time component [#674]

  ⚠️ **This requires migrating your database**.

  You can skip it to maintain current timestamp precision (up to seconds). No sample ROM migration provided. Sample AR migration: https://github.com/RailsEventStore/rails_event_store/blob/1036f852df4abb06f49f0a6915af306eb932cdf3/rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates/created_at_precision_template.rb

  Related: https://blog.arkency.com/how-to-migrate-large-database-tables-without-a-headache/

- Change: Store timestamp only in a dedicated, indexed column making it independent of serializer. [#729, #627, #674]

  This means timestamp is no longer present in serialized metadata within database table. Timestamp is still present in event object metadata.

  This also means that historical data takes `created_at` column as a source of a timestamp. This can introduce a sub-second drift in timestamps.

  If that drift is problematic to you, consider migrating the timestamp from `metadata` to `created_at`. If your serializer was YAML, this could be used to extract the timestamp in MySQL:

  ```
  SELECT STR_TO_DATE(SUBSTR(metadata, LOCATE(':timestamp: ', metadata) + 12, 31), '%Y-%m-%d %H:%i:%s.%f') FROM event_store_events;
  ```

- Add: Support for Bi-Temporal Event Sourcing. [#765]

  ⚠️ **This requires migrating your database and it is not optional**.

  No sample ROM migration provided. Sample AR migration: https://github.com/RailsEventStore/rails_event_store/blob/1036f852df4abb06f49f0a6915af306eb932cdf3/rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates/add_valid_at_template.rb

- Performance: Optimize storage of global stream. Cut by half the number of rows needed in `event_store_events_in_streams`. One insert statement less for non-named stream appends. [#514, #673]

  ⚠️ **This requires migrating your database and it is not optional**.

  No sample ROM migration provided. Sample AR migration: https://github.com/RailsEventStore/rails_event_store/blob/1036f852df4abb06f49f0a6915af306eb932cdf3/rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates/no_global_stream_entries_template.rb

### 1.3.0

Changes up-to version 1.3.0 can be tracked at [releases page](https://github.com/RailsEventStore/rails_event_store/releases).

### 0.1.0 (03.04.2018)

- Implemented ROM SQL adapter
- Add `rom-sql` 2.4.0 dependency
- Add `rom-repository` 2.0.2 dependency
- Add `rom-changeset` 1.0.2 dependency
- Add `sequel` 4.49 dependency
