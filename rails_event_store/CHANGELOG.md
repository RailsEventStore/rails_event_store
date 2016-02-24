### HEAD

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
