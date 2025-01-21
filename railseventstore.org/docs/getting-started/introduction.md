---
title: Introduction
---

## Create new Rails application

Just use provided application template and run:

```
rails new -m https://railseventstore.org/new YOUR-APP-NAME
```

## What's included?

- Rails Event Store gem added to `Gemfile` (latest version)
- Rails Event Store data model migration generated and executed
- Rails Event Store initializer generated with default configuration
- Rails Event Store Browser mounted (available at `http://localhost:3000/res`)

## What next?

- check Rails Event Store setup defined in `config/initializers/rails_event_store.rb`, learn more how to setup Rails Event Store [here](./install)
- decide if default `YAML` serialization suits your needs, see more about serialization formats [here](../advanced-topics/event-serialization-formats)
- start implementing your domain, use `bounded_context` gem's generators to initialize folders structure for your domain model (use `rails generate rails_event_store:bounded_context YOUR-BOUNDED-CONTEXT-NAME` command)
- implement your aggregates using `AggregateRoot` module, see how [here](../core-concepts/event-sourcing)
- subscribe to domain events published, [check how](../core-concepts/subscribe) to define subscriptions and event handlers
- learn Command pattern and [how to](../advanced-topics/command-bus) use Arkency's command bus to decouple your domain model from controllers
- check [how to](../core-concepts/rspec) use provied `RSpec` matchers
- learn more about:
  - [reading](../core-concepts/read) domain events
  - [publishing](../core-concepts/publish) domain events
  - logging [request metadata](../core-concepts/request-metadata)
  - concurrencycontrol using [expected version](../core-concepts/expected-version)
  - possible [errors](../core-concepts/client-errors)

API documentation is available [here](./api)
