---
title: 'Mapping handlers to events'
sidebar_position: 8
---

RailsEventStore client provides an API that helps you find all subscribers (also called event handlers) for specified event type.

This method is also useful when you have to answer the question if the handler subscribed to an event properly.

## Example
Use following method to find all handlers for event of specific type.

```ruby
event_store.subscribers_for(AccountUpdated) # => [...]
```

This method returns array of all subscribers that subscribe to specified type of event.
