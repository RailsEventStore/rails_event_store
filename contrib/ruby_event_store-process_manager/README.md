# ruby_event_store-process_manager

Build stateful process managers on top of [RubyEventStore](https://railseventstore.org). The state is rebuilt from events before each reaction, so a process can coordinate events from multiple parts of an application without a separate state store.

## Installation

Add the gem to your `Gemfile`:

```ruby
gem "ruby_event_store-process_manager"
```

## Usage

This process releases an authorized payment when its order expires:

```ruby
class ReleasePaymentOnOrderExpiration
  include RubyEventStore::ProcessManager.with_state { ProcessState }

  subscribes_to(
    Payments::PaymentAuthorized,
    Payments::PaymentReleased,
    Pricing::OfferExpired
  )

  private

  def fetch_id(event)
    event.data.fetch(:order_id)
  end

  def apply(event)
    case event
    when Payments::PaymentAuthorized
      state.with(payment_authorized: true)
    when Payments::PaymentReleased
      state.with(payment_authorized: false)
    when Pricing::OfferExpired
      state.with(order_expired: true)
    else
      state
    end
  end

  def act
    command_bus.call(Payments::ReleasePayment.new(order_id: id)) if state.release?
  end

  ProcessState = Data.define(:payment_authorized, :order_expired) do
    def initialize(payment_authorized: false, order_expired: false) = super

    def release?
      payment_authorized && order_expired
    end
  end
end
```

Subscribe it to the event store:

```ruby
process = ReleasePaymentOnOrderExpiration.new(event_store, command_bus)

event_store.subscribe(
  process,
  to: ReleasePaymentOnOrderExpiration.subscribed_events
)
```

`fetch_id` identifies the process instance, `apply` evolves its state, and `act` issues commands based on the rebuilt state. The state class must support a no-argument constructor. `apply` must always return the next state, including for events that do not change it.

## Browser integration

The gem ships an extension for [RubyEventStore::Browser](https://railseventstore.org/docs/advanced-topics/browser/). Streams following the `ProcessClassName$id` naming convention get a "Process state" link, leading to a view that replays the process state step by step — showing the state after each event, next to the current state of the process.

```ruby
require "ruby_event_store/process_manager/browser_extension"

RubyEventStore::Browser::App.for(
  event_store_locator: -> { Rails.configuration.event_store },
  extensions: [RubyEventStore::ProcessManager::BrowserExtension.new]
)
```

The view rebuilds the state through the public `replay(events)` API every process manager exposes — it folds `apply` over the events starting from `initial_state` and returns the successive states. `act` is never invoked, so browsing the process state has no side effects.

## License

MIT
