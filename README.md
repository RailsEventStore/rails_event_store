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
```

```ruby
stream_name = "order_1"
event_data = {
               data: { data: "sample" },
               event_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
             }
event = OrderCreated.new(event_data)

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
event_data = {
               data: { data: "sample" },
               event_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
             }
event = OrderCreated.new(event_data)
expected_version = "850c347f-423a-4158-a5ce-b885396c5b73" #last event_id
client.publish_event(event, stream_name, expected_version)
```

#### Reading stream's events forward in batch

```ruby
stream_name = "order_1"
start = "850c347f-423a-4158-a5ce-b885396c5b73"
count = 40
client.read_all_events(stream_name, start, count)
```

#### Reading all events from stream forward

This method allows us to load all stream's events ascending.

```ruby
stream_name = "order_1"
client.read_all_events(stream_name)
```

#### Reading all events forward

This method allows us to load all stored events ascending.

```ruby
client.read_all_streams
```

#### Deleting stream

You can permanently delete all events from a specific stream. Use this wisely.

```ruby
stream_name = "product_1"
client.delete_stream(stream_name)
```

#### Subscribing to events

To listen on specific events synchronously you have to create subscriber reprezentation. The only requirement is that subscriber class has to implement the 'handle_event(event)' method.

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
client.subscribe(invoice)
```

#### Resources

There're already few blogposts about Rails EventStore. Check them out:

* [Why use Event Sourcing](http://blog.arkency.com/2015/03/why-use-event-sourcing/)
* [The Event Store for Rails developers](http://blog.arkency.com/2015/04/the-event-store-for-rails-developers/)
* [Fast introduction to Event Sourcing for Ruby programmers](http://blog.arkency.com/2015/03/fast-introduction-to-event-sourcing-for-ruby-programmers/)
* [Why I want to introduce mutation testing to the rails_event_store gem](http://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/)
