### 0.12.0 (10.08.2016)

* Change: Updated Ruby Event Store method calls according to the newer version PR #53

### 0.11.0 (12.07.2016)

* Breaking change in domain event class (Part of PR #48)
  * no more simple `TestEvent.new(some_attr: 'some value')`
    use `TestEvent.new(data: { some_attr: 'some value' })` instead
  * all data & metadata attributes accessible via `data` & `metadata` properties
    of event class
  * This will avoid name clashes when defining domain event data,
    especially important for `event_id`
* Breaking change: deprecated `handle_event` method removed, use `call` instead
  * some domain event handlers might need method rename
* Change: Mark aliased methods as deprecated (soon to be removed)
* Change: Update RubyEventStore to 0.11.0 PR #48
  * RubyEventStore::Facade renamed to RubyEventStore::Client
* Fix: Improve mutation tests coverage PR #47

### 0.10.0 (30.06.2016)

* Change: Rails request details in event metadata PR #39
* Change: Add dynamic subscriptions (implemented by ruby_event_store 0.9.0) PR #43
* Fix: In-memory sqlite3 with schema load over prebaked filesystem blob in testing  PR #41

### 0.9.0 (24.06.2016)

* Change: ruby_event_store updated to 0.9.0 (Call instead of handle_event)
* Change: aggregate_root updated to 0.3.1 (licensing info)
* Fix: Clarify Licensing terms #36 - MIT licence it is from now

### 0.8.0 (21.06.2016)

* Change: ruby_event_store updated to 0.8.0 (dynamic subscriptions)
* Change: aggregate_root updated to 0.3.0 (fix circular dependency)
* Change: remove SlackEventHandler

### 0.7.0 (01.06.2016)

* Change: ruby_event_store updated to 0.6.0 (adding basic projections support)

### 0.6.1 (25.05.2016)

* Fix: Allow to read events backward PR #32 (bugfix)

### 0.6.0 (11.04.2016)

* Change: EventRepository moved to separate gem [rails_event_store_active_record](http://github.com/arkency/rails_event_store_active_record)
* Change: rails_event_store_active_record updated to version 0.5.1 - allows to use custom event class

### 0.5.0 (21.03.2016)

* Align with changes in `ruby_event_store` 0.5.0:
  * Change: Event class refactoring to make default values more explicit
  * Change: Let event broker to be given as a dependency
  * Change: No nils, use symbols instead - :any & :none replaced meaningless nil value
  * Change: Remove Event#event_type - use class instead
* Fix: Typo fix (appent_to_stream corrected to append_to_stream)
* Change: Encapsulate internals fo RailsEventStore::Client
* Change: Hide `ruby_event_store` internals by adding classes in RailsEventStore module

### 0.4.1 (17.03.2016)

* Fix: aggregate_root gem aligned with changes in rails_event_store

### 0.4.0 (17.03.2016)

* Change: Use class names to subscribe events (ruby_event_store update to  0.4.0)
* Change: EventRepository now recreate events using orginal classes

### 0.3.1 (13.03.2016)

* Update to ruby_event_store 0.3.1 - fix changing timestamp on reads from repository

### 0.3.0 (03.03.2016)

* Update to ruby_event_store 0.3.0 - see ruby_event_store changelog for more details
* Implement reading forward & backward (aliasold methods to read forward)
* Implement paging when reading from all streams

### 0.2.2 (25.02.2016)

* Restore AggregateRoot in RES, but this time as a dependency on aggregate_root gem

### 0.2.1 (25.02.2016)

* Fix: Error when trying to #read_all_streams #20

### 0.2.0 (29.01.2016)

* Removed EventEntity class
* All read & returned events are not instances of RailsEventStore::Event class
* RailsEventStore::Event class allows for easier events creation and access to data attributes
* AggregateRoot module & repository extracted to new gem (aggregate_root)

### 0.1.2 (26.05.2015)

* Moved most core features to the separate gem `ruby_event_store`. We left only rails related implementation here.
* It's now assumed that `event_id` has a unique index in the database (the same is applied to the initial migration generator)
* Model is no longer validating uniqueness of `event_id` via ActiveRecord
* Event does not need any data now, it can be created just like `OrderCreated.new` (without any arguments)
* Migration generator is no more generating the `updated_at` field in the `event_store_events` table. We also advise to remove this column, since events shouldn't be *ever* modified.
* In the event's metadata there's a new field `published_at`
* Added the `subscribe_to_all_events` method to `RailsEventStore::Client`
* Subscribing to only one event via `client.subscribe(subscriber, 'OrderCreated')` no longer works. You should use `client.subscribe(subscriber, ['OrderCreated'])` instead.
* Default event's name is no longer `OrderCreated` for the `OrderCreated` event in the `Orders` namespace, now it's `Orders::OrderCreated`

### 0.1.1 (22.04.2015)

Initial release.
