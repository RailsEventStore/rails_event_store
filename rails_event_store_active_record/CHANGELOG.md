Further changes can be tracked at [releases page](https://github.com/RailsEventStore/rails_event_store/releases).

### 0.6.14 (unreleased)

* Run tests in random order

### 0.6.13 (24.08.2017)

* Fix: Generate migration with version number for Rails versions that support it. Fixes compatibility with Rails 5.1.

### 0.6.12 (21.08.2017)

* ruby_event_store updated to 0.14.0

### 0.6.11 (8.02.2016)

* Fix: Explicit order when querying forward. Leaving it implcit to database engine choice gives different results on different engines.

### 0.6.10 (23.11.2016)

* Change: requires update to allow void active_record dependency when using RailsEventStore without RailsEventStoreActiveRecord

### 0.6.9 (18.10.2016)

* ruby_event_store updated to 0.13.0

### 0.6.8 (11.08.2016)

* ruby_event_store updated to 0.12.1
* make this gem mutant free - 100% mutation tests coverage

### 0.6.7 (10.08.2016)

* ruby_event_store updated to 0.12.0

### 0.6.6 (12.07.2016)

* ruby_event_store updated to 0.11.0

### 0.6.5 (12.07.2016)

* ruby_event_store updated to 0.10.1
* Fix: fixed bug which have made repository unable to load a event with associated data or metadata. Tests for this bug were added in ruby_event_store 0.10.1

### 0.6.4 (12.07.2016)

* ruby_event_store updated to 0.10.0

### 0.6.3 (24.06.2016)

* Change: ruby_event_store updated to 0.9.0 (Call instead of handle_event)
* Fix: Clarify Licensing information

### 0.6.2 (21.06.2016)

* ruby_event_store updated to 0.8.0

### 0.6.1 (21.06.2016)

* ruby_event_store updated to 0.7.0
* add indexes for commonly searched fields: time and type to migration template PR #6

### 0.6.0 (25.05.2016)

* ruby_event_store updated to 0.6.0

### 0.5.1 (11.04.2016)

* Change: Rename migration generator from 'migrate' to 'migration' PR #3
* Change: Allow to provide a custom event class #2


### 0.5.0 (25.03.2016)

* Code moved from RailsEventStore 0.5.0
