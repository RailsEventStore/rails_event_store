* Fix: When using `append_to_stream`, expected version is no longer compared using `equal?` commit bdbe4600073d278cbf1024e8d49801fec768f6a7
* Change: Creating events with data is now done using `data` keyword argument. Previously events were created using the syntax `OrderCreated.new(order_id: 123)`, now it has to be `OrderCreated.new(data: { order_id: 123 })`. PR #24
* Change: Only events with the same name, event_id and data are equal - metadata is no longer taken into account PR #24
* Change: `metadata[:timestamp]` is now set when event is appended to the stream, not when it is initialized PR #24
* Change: Initialization of `RubyEventStore::Facade` is now using keyword arguments PR #24
* Add support to `metadata_proc` PR #24
* `ClosedStruct` is now a dependency PR #24

### 0.9.0 (24.06.2016)

* Change: Call instead of handle_event, handle_event stays for now but is deprecated PR #18
* Fix: Clarify Licensing terms #23 - MIT licence it is from now

### 0.8.0 (21.06.2016)

* Change: Possibility to create projection based on all events PR #19

### 0.7.0 (21.06.2016)

* Change: support for Dynamic subscriptions PR #20
* Change: Add lint for 3rd party implementations of event broker PR #21

### 0.6.0 (25.05.2016)

* Ability to provide a custom dispatcher to PubSub::Broker PR #12
* Add support for projections PR #13
* Added prettier message for case of missing #handle_event method. PR #14
* Make file to run all the things PR #15

### 0.5.0 (21.03.2016)

* Change: Event class refactoring to make default values more explicit PR #11
* Change: No nils, use symbols instead - :any & :none replaced meaningless nil value
* Change: Let event broker to be given as a dependency
* Change: Remove Event#event_type - use class instead PR #10

### 0.4.0 (17.03.2016)

* Change: Use class names to subscribe events PR #8

### 0.3.1 (13.03.2016)

* Fix Don't overwrite timestamps when reading from repository

### 0.3.0 (03.03.2016)

* Change: read_all_streams won't group_by results by stream name PR #4
* Change: new way of define attributes of domain event PR #5
* Change: reading forward and backward, refactored facade interface #6
* Change: in memory event repository is now part of the gem, with shared specification PR #7

### 0.2.0 (27.01.2016)

* Change: Return the event that the repository returns PR #2

### 0.1.0 (26.05.2015)

Initial version
