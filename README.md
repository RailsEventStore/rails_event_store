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

[![CircleCI](https://circleci.com/gh/RailsEventStore/rails_event_store.svg?style=shield)](https://circleci.com/gh/RailsEventStore/rails_event_store)
[![Gem Version](https://badge.fury.io/rb/rails_event_store.svg)](https://badge.fury.io/rb/rails_event_store)
[![Downloads](https://badgen.net/rubygems/dt/ruby_event_store)](https://rubygems.org/gems/ruby_event_store)
[![Maintainability](https://badgen.net/codeclimate/maintainability/RailsEventStore/rails_event_store)](https://codeclimate.com/github/RailsEventStore/rails_event_store/maintainability)
[![Documentation](https://inch-ci.org/github/RailsEventStore/rails_event_store.svg?branch=master)](https://inch-ci.org/github/RailsEventStore/rails_event_store)

We're aiming for 100% mutation coverage in this project. This is why:

* [Why I want to introduce mutation testing to the rails_event_store gem](https://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/)
* [Mutation testing and continuous integration](https://blog.arkency.com/2015/05/mutation-testing-and-continuous-integration/)

Whenever you fix a bug or add a new feature, we require that the coverage doesn't go down.

## Contributing

This single repository hosts several gems and website with documentation. Check the contribution [guide](https://railseventstore.org/community/).

## About

<img src="https://arkency.com/images/arkency.png" alt="Arkency" width="60px" align="left" />

This repository is funded and maintained by [Arkency](https://arkency.com). Check out our other [open-source projects](https://github.com/arkency) and what else we have at [RES](https://github.com/RailsEventStore).

Consider [hiring us](https://arkency.com/hire-us) and make sure to check out [our blog](https://blog.arkency.com).

### Learn more about DDD & Event Sourcing

Check our [Rails + Domain Driven Design Workshop](https://blog.arkency.com/ddd-training/).
Why You should attend? Robert has explained this in a [blogpost](https://blog.arkency.com/2016/12/why-would-you-even-want-to-listen-about-ddd/).

### Read about Domain Driven Rails

You may also consider buying the [Domain-Driven Rails book](https://blog.arkency.com/domain-driven-rails/).
