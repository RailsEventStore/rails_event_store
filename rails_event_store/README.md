# EventStore

Production ready Ruby implementation of an EventStore based on Active Record.

## Installation

1. Add this line to your application's Gemfile:

```ruby
gem 'rails_event_store'
```

2. Generate table to store events in you DB. For this purpose you can use provided migration generator.

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

#publishing global event
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
expected_version = 1 #last event_id
client.append_to_stream(event, stream_name, expected_version)
```

#### Reading stream's events forward in batch

```ruby
stream_name = "order_1"
start = 1
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
