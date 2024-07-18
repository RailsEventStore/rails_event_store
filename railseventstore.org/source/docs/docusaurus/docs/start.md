---
title: Getting started
sidebar_position: 1
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

- check Rails Event Store setup defined in `config/initializers/rails_event_store.rb`, learn more how to setup Rails Event Store [here](/docs/v2/install)
- decide if default `YAML` serialization suits your needs, see more about serialization formats [here](/docs/v2/mapping_serialization)
- start implementing your domain, use `bounded_context` gem's generators to initialize folders structure for your domain model (use `rails generate rails_event_store:bounded_context YOUR-BOUNDED-CONTEXT-NAME` command)
- implement your aggregates using `AggregateRoot` module, see how [here](/docs/v2/app)
- subscribe to domain events published, [check how](/docs/v2/subscribe) to define subscriptions and event handlers
- learn Command pattern and [how to](/docs/v2/command_bus) use Arkency's command bus to decouple your domain model from controllers
- check [how to](/docs/v2/rspec) use provied `RSpec` matchers
- learn more about:
  - [reading](/docs/v2/read) domain events
  - [publishing](/docs/v2/publish) domain events
  - logging [request metadata](/docs/v2/request_metadata)
  - concurrencycontrol using [expected version](/docs/v2/expected_version)
  - possible [errors](/docs/v2/exceptions)

API documentation is available [here](/docs/v2/api)
