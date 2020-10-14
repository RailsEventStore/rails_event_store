---
title: Getting started
---

## Create new Rails application

Just use provided application template and run:

```
rails new -m https://railseventstore.org/new YOUR-APP-NAME
```

## What's included?

* Rails Event Store gem added to `Gemfile` (latest version)
* Rails Event Store data model migration generated and executed
* Rails Event Store initializer generated with default configuration
* Rails Event Store Browser mounted (available at `http://localhost:3000/res`)

## What next?

* check Rails Event Store setup defined in `config/initializers/rails_event_store.rb`, learn more how to setup Rails Event Store [here](/docs/install)
* decide if default `YAML` serialization suits your needs, see more about serialization formats [here](/docs/mapping_serialization)
* start implementing your domain, use `bounded_context` gem's generators to initialize folders structure for your domain model (use `rails generate bounded_context:bounded_context YOUR-BOUNDED-CONTEXT-NAME` command)
* implement your aggregates using `AggregateRoot` module, see how [here](/docs/app)
* subscribe to domain events published, [check how](/docs/subscribe) to define subscriptions and event handlers
* learn Command pattern and [how to](/docs/command_bus) use Arkency's command bus to decouple your domain model from controllers
* check [how to](/docs/rspec) use provied `RSpec` matchers
* learn more about:
  * [reading](/docs/read) domain events
  * [publishing](/docs/publish) domain events
  * logging [request metadata](/docs/request_metadata)
  * concurrencycontrol using [expected version](/docs/expected_version)
  * possible [errors](/docs/exceptions)

API documentation documentation is available [here](/docs/api)
