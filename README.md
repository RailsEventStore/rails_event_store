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

Creating a single event:

```ruby
stream_name = "order_1"
event_data = { event_type: "OrderCreated",
               data: { data: "sample" },
               event_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd" }
client.publish_event(stream_name, event_data)
```

OR

```ruby
EventData = Struct.new(:data, :event_type)
stream_name = "order_1"
event_data = EventData.new({ data: "sample" }, "OrderCreated")
client.publish_event(stream_name, event_data)
```

Creating a single event with optimistic locking:

```ruby
stream_name = "order_1"
event_data = { event_type: "OrderCreated", data: { data: "sample" }}
expected_version = "b2d506fd-409d-4ec7-b02f-c6d2295c7edd" #last event_id
client.append_to_stream(stream_name, event_data, expected_version)
```

#### Reading stream's event forward

```ruby
stream_name = "order_1"
start = "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
count = 40
client.read_events_forward(stream_name, start, count)
```

```

#### Reading all stream's event forward

This method allows us to load all stream's events ascending.

```ruby
stream_name = "order_1"
client.read_all_events_forward(stream_name)
```


