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

![Ruby Event Store](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store/badge.svg)
![Rails Event Store](https://github.com/RailsEventStore/rails_event_store/workflows/rails_event_store/badge.svg)
![Rails Event Store Active Record](https://github.com/RailsEventStore/rails_event_store/workflows/rails_event_store_active_record/badge.svg)
![Ruby Event Store Rspec](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-rspec/badge.svg)
![Ruby Event Store Browser](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-browser/badge.svg)
![Aggregate Root](https://github.com/RailsEventStore/rails_event_store/workflows/aggregate_root/badge.svg)


[![Gem Version](https://badge.fury.io/rb/rails_event_store.svg)](https://badge.fury.io/rb/rails_event_store)
[![Downloads](https://badgen.net/rubygems/dt/ruby_event_store)](https://rubygems.org/gems/ruby_event_store)
[![Maintainability](https://badgen.net/codeclimate/maintainability/RailsEventStore/rails_event_store)](https://codeclimate.com/github/RailsEventStore/rails_event_store/maintainability)
[![Documentation](https://inch-ci.org/github/RailsEventStore/rails_event_store.svg?branch=master)](https://inch-ci.org/github/RailsEventStore/rails_event_store)

We're aiming for 100% mutation coverage in this project. This is why:

* [Why I want to introduce mutation testing to the rails_event_store gem](https://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/)
* [Mutation testing and continuous integration](https://blog.arkency.com/2015/05/mutation-testing-and-continuous-integration/)

Whenever you fix a bug or add a new feature, we require that the coverage doesn't go down.

## Contributing

This single repository hosts several gems and website with documentation — see the contribution [guide](https://railseventstore.org/community/).

## About

<img src="https://arkency.com/logo.svg" alt="Arkency" height="48" align="left" />

This repository is funded and maintained by [arkency](https://arkency.com). Make sure to check out our [Rails Architect Masterclass training](https://arkademy.dev) and long-term [support plans](https://railseventstore.org/support/) available.
