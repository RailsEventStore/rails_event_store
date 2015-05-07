### HEAD

* It's now assumed that `event_id` has unique index in database (the same is applied to initial migration generator)
* Model is no longer validating uniqueness of `event_id` via ActiveRecord
* Event does not need any data now, it can be created just like `OrderCreated.new` (without any arguments)
* Migration generator is no more generating `updated_at` field in `event_store_events` table. We also advise to remove this column, since events shouldn't be *ever* modified.
* In event's metadata there's new field `published_at`
* Added `subscribe_to_all_events` method to `RailsEventStore::Client`
* Subscribing to only one event via `client.subscribe(subscriber, 'OrderCreated')` no longer works. You should use `client.subscribe(subscriber, ['OrderCreated'])` instead.
* Default event's name is no longer `OrderCreated` for event `OrderCreated` in namespace `Orders`, now it's `Orders::OrderCreated`

### 0.1.1 (22.04.2015)

Initial release.
