# Subscribing to events

To listen on specific events synchronously you have to create subscriber representation. The only requirement is that subscriber class has to implement the `handle_event(event)` method.

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
client.subscribe(invoice, [PriceChanged, ProductAdded])
```

* You can also listen on all incoming events

```ruby
invoice = InvoiceReadModel.new
client.subscribe_to_all_events(invoice)
```
