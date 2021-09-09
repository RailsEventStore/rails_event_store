# Rails Event Store

[Rails Event Store (RES)](https://railseventstore.org/) is a library for publishing, consuming, storing and retrieving events. It's your best companion for going with an event-driven architecture for your Rails application.

You can use it:

<ul>
<li>as your <a href="https://railseventstore.org/docs/pubsub/">Publish-Subscribe bus</a></li>
<li>to decouple core business logic from external concerns in Hexagonal style architectures</li>
<li>as <a href="https://blog.arkency.com/2016/05/domain-events-over-active-record-callbacks/">an alternative to ActiveRecord callbacks and Observers</a></li>
<li>as a communication layer between loosely coupled components</li>
<li>to react to published events synchronously or asynchronously</li>
<li>to extract side-effects (notifications, metrics etc) from your controllers and services into event handlers</li>
<li>to build an audit-log</li>
<li>to create read-models</li>
<li>to implement event-sourcing</li>
</ul>

## Documentation

Documentation, tutorials and code samples are available at [https://railseventstore.org](https://railseventstore.org).

## Code status

We're aiming for 100% mutation coverage in this project. This is why:

* [Why I want to introduce mutation testing to the rails_event_store gem](https://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/)
* [Mutation testing and continuous integration](https://blog.arkency.com/2015/05/mutation-testing-and-continuous-integration/)

Whenever you fix a bug or add a new feature, we require that the coverage doesn't go down.

### RailsEventStore gems


|  Name | CI | Version | Downloads |
|---|---|---|---|
|[rails_event_store](/rails_event_store)|![rails_event_store](https://github.com/RailsEventStore/rails_event_store/workflows/rails_event_store/badge.svg)|[![rails_event_store](https://badge.fury.io/rb/rails_event_store.svg)](https://badge.fury.io/rb/rails_event_store)|[![rails_event_store](https://badgen.net/rubygems/dt/rails_event_store)](https://rubygems.org/gems/rails_event_store)|
|[rails_event_store_active_record](/rails_event_store_active_record)|![rails_event_store_active_record](https://github.com/RailsEventStore/rails_event_store/workflows/rails_event_store_active_record/badge.svg)|[![rails_event_store_active_record](https://badge.fury.io/rb/rails_event_store_active_record.svg)](https://badge.fury.io/rb/rails_event_store_active_record)|[![rails_event_store_active_record](https://badgen.net/rubygems/dt/rails_event_store_active_record)](https://rubygems.org/gems/rails_event_store_active_record)|
|[ruby_event_store](/ruby_event_store)|![ruby_event_store](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store/badge.svg)|[![ruby_event_store](https://badge.fury.io/rb/ruby_event_store.svg)](https://badge.fury.io/rb/ruby_event_store)|[![ruby_event_store](https://badgen.net/rubygems/dt/ruby_event_store)](https://rubygems.org/gems/ruby_event_store)|
|[ruby_event_store-browser](/ruby_event_store-browser)|![ruby_event_store-browser](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-browser/badge.svg)|[![ruby_event_store-browser](https://badge.fury.io/rb/ruby_event_store-browser.svg)](https://badge.fury.io/rb/ruby_event_store-browser)|[![ruby_event_store-browser](https://badgen.net/rubygems/dt/ruby_event_store-browser)](https://rubygems.org/gems/ruby_event_store-browser)|
|[ruby_event_store-rspec](/ruby_event_store-rspec)|![ruby_event_store-rspec](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-rspec/badge.svg)|[![ruby_event_store-rspec](https://badge.fury.io/rb/ruby_event_store-rspec.svg)](https://badge.fury.io/rb/ruby_event_store-rspec)|[![ruby_event_store-rspec](https://badgen.net/rubygems/dt/ruby_event_store-rspec)](https://rubygems.org/gems/ruby_event_store-rspec)|
|[aggregate_root](/aggregate_root)|![aggregate_root](https://github.com/RailsEventStore/rails_event_store/workflows/aggregate_root/badge.svg)|[![aggregate_root](https://badge.fury.io/rb/aggregate_root.svg)](https://badge.fury.io/rb/aggregate_root)|[![aggregate_root](https://badgen.net/rubygems/dt/aggregate_root)](https://rubygems.org/gems/aggregate_root)|


### Contributed gems

|  Name | CI | Version | Downloads |
|---|---|---|---|
|[ruby_event_store-outbox](/contrib/ruby_event_store-outbox)|![ruby_event_store-outbox](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-outbox/badge.svg)|[![ruby_event_store-outbox](https://badge.fury.io/rb/ruby_event_store-outbox.svg)](https://badge.fury.io/rb/ruby_event_store-outbox)|[![ruby_event_store-outbox](https://badgen.net/rubygems/dt/ruby_event_store-outbox)](https://rubygems.org/gems/ruby_event_store-outbox)|
|[ruby_event_store-protobuf](/contrib/ruby_event_store-protobuf)|![ruby_event_store-protobuf](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-protobuf/badge.svg)|[![ruby_event_store-protobuf](https://badge.fury.io/rb/ruby_event_store-protobuf.svg)](https://badge.fury.io/rb/ruby_event_store-protobuf)|[![ruby_event_store-protobuf](https://badgen.net/rubygems/dt/ruby_event_store-protobuf)](https://rubygems.org/gems/ruby_event_store-protobuf)|
|[ruby_event_store-newrelic](/contrib/ruby_event_store-newrelic)|![ruby_event_store-newrelic](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-newrelic/badge.svg)|[![ruby_event_store-newrelic](https://badge.fury.io/rb/ruby_event_store-newrelic.svg)](https://badge.fury.io/rb/ruby_event_store-newrelic)|[![ruby_event_store-newrelic](https://badgen.net/rubygems/dt/ruby_event_store-newrelic)](https://rubygems.org/gems/ruby_event_store-newrelic)|
|[ruby_event_store-profiler](/contrib/ruby_event_store-profiler)|![ruby_event_store-profiler](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-profiler/badge.svg)|[![ruby_event_store-profiler](https://badge.fury.io/rb/ruby_event_store-profiler.svg)](https://badge.fury.io/rb/ruby_event_store-profiler)|[![ruby_event_store-profiler](https://badgen.net/rubygems/dt/ruby_event_store-profiler)](https://rubygems.org/gems/ruby_event_store-profiler)|
|[ruby_event_store-flipper](/contrib/ruby_event_store-flipper)|![ruby_event_store-flipper](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-flipper/badge.svg)|[![ruby_event_store-flipper](https://badge.fury.io/rb/ruby_event_store-flipper.svg)](https://badge.fury.io/rb/ruby_event_store-flipper)|[![ruby_event_store-flipper](https://badgen.net/rubygems/dt/ruby_event_store-flipper)](https://rubygems.org/gems/ruby_event_store-flipper)|
|[ruby_event_store-transformations](/contrib/ruby_event_store-transformations)|![ruby_event_store-transformations](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-transformations/badge.svg)|[![ruby_event_store-transformations](https://badge.fury.io/rb/ruby_event_store-transformations.svg)](https://badge.fury.io/rb/ruby_event_store-transformations)|[![ruby_event_store-transformations](https://badgen.net/rubygems/dt/ruby_event_store-transformations)](https://rubygems.org/gems/ruby_event_store-transformations)|
|[ruby_event_store-rom](/contrib/ruby_event_store-rom)|![ruby_event_store-rom](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-rom/badge.svg)|[![ruby_event_store-rom](https://badge.fury.io/rb/ruby_event_store-rom.svg)](https://badge.fury.io/rb/ruby_event_store-rom)|[![ruby_event_store-rom](https://badgen.net/rubygems/dt/ruby_event_store-rom)](https://rubygems.org/gems/ruby_event_store-rom)|
|[ruby_event_store-sidekiq_scheduler](/contrib/ruby_event_store-sidekiq_scheduler)|![ruby_event_store-sidekiq_scheduler](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-sidekiq_scheduler/badge.svg)|[![ruby_event_store-sidekiq_scheduler](https://badge.fury.io/rb/ruby_event_store-sidekiq_scheduler.svg)](https://badge.fury.io/rb/ruby_event_store-sidekiq_scheduler)|[![ruby_event_store-sidekiq_scheduler](https://badgen.net/rubygems/dt/ruby_event_store-sidekiq_scheduler)](https://rubygems.org/gems/ruby_event_store-sidekiq_scheduler)|
|[minitest-ruby_event_store](/contrib/minitest-ruby_event_store)|![minitest-ruby_event_store](https://github.com/RailsEventStore/rails_event_store/workflows/minitest-ruby_event_store/badge.svg)|[![minitest-ruby_event_store](https://badge.fury.io/rb/minitest-ruby_event_store.svg)](https://badge.fury.io/rb/minitest-ruby_event_store)|[![minitest-ruby_event_store](https://badgen.net/rubygems/dt/minitest-ruby_event_store)](https://rubygems.org/gems/minitest-ruby_event_store)|
|[dres_rails](/contrib/dres_rails)|![dres_rails](https://github.com/RailsEventStore/rails_event_store/workflows/dres_rails/badge.svg)|[![dres_rails](https://badge.fury.io/rb/dres_rails.svg)](https://badge.fury.io/rb/dres_rails)|[![dres_rails](https://badgen.net/rubygems/dt/dres_rails)](https://rubygems.org/gems/dres_rails)|
|[dres_client](/contrib/dres_client)|![dres_client](https://github.com/RailsEventStore/rails_event_store/workflows/dres_client/badge.svg)|[![dres_client](https://badge.fury.io/rb/dres_client.svg)](https://badge.fury.io/rb/dres_client)|[![dres_client](https://badgen.net/rubygems/dt/dres_client)](https://rubygems.org/gems/dres_client)|

## Contributing

This single repository hosts several gems and website with documentation — see the contribution [guide](https://railseventstore.org/community/).

## About

<img src="https://arkency.com/logo.svg" alt="Arkency" height="48" align="left" />

This repository is funded and maintained by [arkency](https://arkency.com). Make sure to check out our [Rails Architect Masterclass training](https://arkademy.dev) and long-term [support plans](https://railseventstore.org/support/) available.
