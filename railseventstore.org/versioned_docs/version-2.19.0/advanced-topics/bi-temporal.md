---
title: Bi-Temporal EventSourcing
---

Sometimes in the Event-Sourced world knowing when a specific event happened is not enough. In some business cases, there's also a necessity to know at which point in time a particular event was valid.
This approach is called Bi-Temporal EventSourcing.

## Example

Consider you're an HR person responsible for dealing with employee salaries. Your tool of choice to gather the data is an Excel sheet and email.
When you gather the information from managers, you put them into an Excel sheet and mail them to payroll. Payroll is taking care of the money getting into employees' bank accounts. You also import the Excel sheet into your HR system, which happens to be Event Sourced.

Usually, things go great and we build our stream of salary-tracking events like this:
![BiTemporalEventSourcingWhenThingsGoSmoothly](/images/bi_temporal_event_sourcing_when_things_go_smoothly.jpg)
However an error might happen. The error might happen when gathering the data from manager or putting it into an Excel sheet.

Instead of asking a developer to modify the event data (events should always be immutable!), you could use a bi-temporal event. Consider the example below:
![BiTemporalEventSourcingValidAt](/images/bi_temporal_valid_at_event_sourcing.jpg)
In this example, the salary was raised on January 1, 2020, and it was also paid out on February 1, 2020. Then the mistake was detected. Instead of modifying the history of events, the new one has been published. The new event describes the proper value of the salary and specifies when the salary is valid.

## Usage

If you decide to use the Bi-Temporal EventSourcing approach for a stream, you have to include the `valid_at` property to the event's metadata.
`valid_at` describes when the event was actually valid, despite when it occurred. Such an event is also often called a Retroactive event.

```ruby
event_store.publish(Event.new(data: {}, metadata: {valid_at: Time.utc(2020,1,1)}))
```

When reading a stream with bi-temporal events you can either read the events by using:

* `as_at` scope, which orders events by `timestamp`, which is the time of appending the event to the stream
* `as_of` scope, which orders events by `valid_at`, which is the time of when the event was actually valid

```ruby
event_store.read.stream("my-stream").as_at.to_a # ordered by time of appending (timestamp)
event_store.read.stream("my-stream").as_of.to_a # ordered by validity time (valid_at)
```
