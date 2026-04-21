---
title: Transactions with Rails Event Store
sidebar_label: Transactions
---

## Philosophy

RailsEventStore shines when it comes to handling transactions.

All Rails projects rely heavily on transactions for consistency.
When projects grow a temptation might be to split some functionality into microservices (with their own database)/

However, this brings a lot of complexity - what used to be part of 1 transaction, now becomes a distributed transaction.

Distributed transactions are a hard problem in computer science.

Using RailsEventStore usually means that you go with the same database for your events as for other parts of your app.
That's the right approach. It simplifies transactions.

It means that publishing events can be part of a bigger transactions.

This makes it relatively easy to also rollback transactions (and thus rollback events).

All in all, it helps introducing events in non-invasive way.
There's no need to change your current infrastructure or refactor large pieces of code.

## Publishing events

Internally, all which is part of `publish` API is transactional.

This means that creation of the event (or more events) itself, appending it to a stream - all is part of 1 transaction.

Note the `start_transaction` block.

```ruby
def add_to_stream(event_ids, stream, expected_version)
  last_stream_version = ->(stream_) do
    @stream_klass.where(stream: stream_.name).order("position DESC").first.try(:position)
  end
  resolved_version = expected_version.resolve_for(stream, last_stream_version)

  start_transaction do
    yield if block_given?
    in_stream =
      event_ids.map.with_index do |event_id, index|
        { stream: stream.name, position: compute_position(resolved_version, index), event_id: event_id }
      end
    @stream_klass.import(in_stream) unless stream.global?
  end
  self
rescue ::ActiveRecord::RecordNotUnique => e
  raise_error(e)
end
```

## Application-level transactions

Many Rails projects follow the concept of one transaction per 1 request (controller action).

Sometimes the transaction is started at the controller level. Sometimes it's done at the service object level.

RES supports this pattern.
When you use event as part of your service objects, they now become part of your bigger transaction.

## Refactoring and transactions

When your service objects grow and you start extracting aggregates - you're still safe.
As long as your code is wrapped with a transaction, your events publishing is now consistent.

If something goes wrong and the transaction is rollbacked, the events are also not persisted in the database.
