[![Build Status](https://travis-ci.org/arkency/rails_event_store.svg?branch=master)](https://travis-ci.org/arkency/rails_event_store)
[![Gem Version](https://badge.fury.io/rb/rails_event_store.svg)](http://badge.fury.io/rb/rails_event_store)
[![Code Climate](https://codeclimate.com/github/arkency/rails_event_store/badges/gpa.svg)](https://codeclimate.com/github/arkency/rails_event_store)
[![Test Coverage](https://codeclimate.com/github/arkency/rails_event_store/badges/coverage.svg)](https://codeclimate.com/github/arkency/rails_event_store)
[![Join the chat at https://gitter.im/arkency/rails_event_store](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/arkency/rails_event_store?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# EventStore

A Ruby implementation of an EventStore based on Active Record.

## Installation

* Add following line to your application's Gemfile:

```ruby
gem 'rails_event_store'
```

* Use provided task to generate a table to store events in you DB.

```ruby
rails generate rails_event_store:migrate
rake db:migrate
```

## Usage

To communicate with ES you have to create instance of `RailsEventStore::Client` class.

```ruby
client = RailsEventStore::Client.new
```

#### Creating new event

Firstly you have to define own event model extending `RailsEventStore::Event` class.

```ruby
class OrderCreated < RailsEventStore::Event
end

# or

OrderCreated = Class.new(RailsEventStore::Event)
```

```ruby
stream_name = "order_1"
event = OrderCreated.new(
          data: "sample",
          event_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
        )
#publishing event for specific stream
client.publish_event(event, stream_name)

#publishing global event. In this case stream_name is 'all'.
client.publish_event(event)
```

#### Creating new event with optimistic locking:

```ruby
class OrderCreated < RailsEventStore::Event
end
```

```ruby
stream_name = "order_1"
event = OrderCreated.new(
          data: "sample",
          event_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
        )
expected_version = "850c347f-423a-4158-a5ce-b885396c5b73" #last event_id
client.publish_event(event, stream_name, expected_version)
```

#### Reading stream's events forward in batch - starting from first event

```ruby
stream_name = "order_1"
count = 40
client.read_events_forward(stream_name, :head, count)
```

In this case `:head` means first event of the stream.

#### Reading stream's events forward in batch - staring from given event

```ruby
# last_read_event is any domain event read or published by rails_event_store

stream_name = "order_1"
start = last_read_event.event_id
count = 40
client.read_events_forward(stream_name, start, count)
```

#### Reading stream's events backward in batch

As in examples above, just use `read_events_backward` instead of `read_events_forward`.
In this case `:head` means last event of the stream.

#### Reading all events from stream forward

This method allows us to load all stream's events ascending.

```ruby
stream_name = "order_1"
client.read_stream_events_forward(stream_name)
```

#### Reading all events from stream forward

This method allows us to load all stream's events descending.

```ruby
stream_name = "order_1"
client.read_stream_events_backward(stream_name)
```

#### Reading all events forward

This method allows us to load all stored events ascending.

This will read first 100 domain events stored in event store.

```ruby
client.read_all_streams_forward(:head, 100)
```

When not specified it reads events starting from `:head` (first domain event
stored in event store) and reads up to `RailsEventStore::PAGE_SIZE`
domain events.

```ruby
client.read_all_streams_forward
```

You could also read batch of domain events starting from any read or published event.

```ruby
client.read_all_streams_forward(last_read_event.event_id, 100)
```

#### Reading all events backward

This method allows us to load all stored events descending.

This will read last 100 domain events stored in event store.
```ruby
client.read_all_streams_backward(:head, 100)
```

When not specified it reads events starting from `:head` (last domain event
stored in event store) and reads up to `RailsEventStore::PAGE_SIZE`
domain events.

```ruby
client.read_all_streams_backward
```

#### Deleting stream

You can permanently delete all events from a specific stream. Use this wisely.

```ruby
stream_name = "product_1"
client.delete_stream(stream_name)
```

#### Subscribing to events

To listen on specific events synchronously you have to create subscriber representation. The only requirement is that subscriber class has to implement the 'handle_event(event)' method.

```ruby
class InvoiceReadModel
  def handle_event(event)
    #we deal here with event's data
  end
end
```

* You can subscribe on specific set of events

```ruby
invoice = InvoiceReadModel.new
client.subscribe(invoice, ['PriceChanged', 'ProductAdded'])
```

* You can also listen on all incoming events

```ruby
invoice = InvoiceReadModel.new
client.subscribe_to_all_events(invoice)
```

#### Building an event sourced application with RailsEventStore gem

ArrgegateRoot module & AggregateReporitory have been extracted from RailsEventStore to separate gem.
See [aggregate_root](https://github.com/arkency/aggregate_root) gem readme to find help how to start.
Also [this example](https://github.com/mpraglowski/cqrs-es-sample-with-res) might be useful.

#### Resources

There're already few blogposts about Rails EventStore. Check them out:

* [Why use Event Sourcing](http://blog.arkency.com/2015/03/why-use-event-sourcing/)
* [The Event Store for Rails developers](http://blog.arkency.com/2015/04/the-event-store-for-rails-developers/)
* [Fast introduction to Event Sourcing for Ruby programmers](http://blog.arkency.com/2015/03/fast-introduction-to-event-sourcing-for-ruby-programmers/)
* [Why I want to introduce mutation testing to the rails_event_store gem](http://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/)

## About

<img src="http://arkency.com/images/arkency.png" alt="Arkency" width="20%" align="left" />

Rails Event Store is funded and maintained by Arkency. Check out our other [open-source projects](https://github.com/arkency).

You can also [hire us](http://arkency.com) or [read our blog](http://blog.arkency.com).
