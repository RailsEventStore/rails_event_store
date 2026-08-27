# RailsEventStore::Inspector

See what RailsEventStore did while you click through your application: which
events were published, which handler took each one, what each of them produced
— and, the part nothing else shows, what did not happen.

A panel rides along with your own pages. There is no separate address to visit,
because the point is watching events appear as you use the application.

## Installation

```ruby
gem "rails_event_store-inspector"
```

That is all. In development the panel appears by itself, as a badge in the
corner of every page.

## What it shows

```
req 44384c8d…                                              ▤ swimlane
  Ordering::OrderSubmitted        2.1 ms   1 handler       ⛓
    └ Invoicing::CreateInvoice    8.4 ms
        Invoicing::InvoiceCreated 0.9 ms   ⚠ no handlers   ⛓
        └ 3 × RES (LinkByEventType, LinkByCorrelationId, LinkByCausationId)
  Ordering::OrderConfirmed        1.2 ms   1 handler       ⛓
    └ Notifications::SendEmail    0.3 ms   → enqueued
```

Events nest under the handler that published them, grouped by the request that
caused them. Times are what each step actually took.

### What did not happen

This is what you cannot get from the log, because absence leaves no line to
grep for:

- **⚠ no handlers** — the event was published and nobody was listening.
  Handlers RailsEventStore wires up itself do not count towards this, or the
  warning would never appear; they collapse into one dimmed line.
- **⚠ scheduled but never enqueued** — an ActiveJob handler was scheduled after
  commit, but the enqueue never followed. The transaction rolled back and the
  handler will not run.

### Links into the Browser

If [RubyEventStore::Browser](https://railseventstore.org/docs/v2/browser/) is
mounted, the event name opens that event, **⛓** opens everything correlated
with it — including what ran later in a job — and **▤ swimlane** lays the
request's streams side by side. Without the Browser they are plain text.

## Configuration

Two knobs, neither of them required.

### Who may look

```ruby
RailsEventStore::Inspector.configure do |config|
  config.enabled = ->(env) { env["warden"]&.user&.staff? }
end
```

A predicate on the request rather than a flag, so "development only" is the
default and not the limit. The default refuses outside development: a
forgotten configuration leaves the inspector off rather than open.

The verdict covers collecting as well as showing. Refused, the middleware
behaves as though it were not in the stack at all.

### Whose events you see

The buffer is shared by everyone the process serves, so entries are scoped.
By default that is a cookie of the inspector's own — always there, unique per
browser, nothing needed from you. If you have something better:

```ruby
config.scope = ->(env) { env["warden"]&.user&.id }
config.scope = ->(env) { ActionDispatch::Request.new(env).session.id }
```

Not the session by default, because a visitor without one would key by nil and
every anonymous visitor would share a single view.

Note this is scoping, not authorization: it answers whose data you see, not
whether you may look. That is what `enabled` is for.

## Before running it anywhere but development

- **`install` decides whether it is there at all**, `enabled` decides whether
  it may watch this request. Setting only the second is enough; setting only
  the first is not.
- **One process only.** The buffer lives in memory, so with several workers a
  request lands in one of them and the panel shows that worker's history.
- **`enabled` is the whole of the access control.** Set it to something real.
- **Cookie scoping is not authorization.** Copying somebody else's cookie value
  shows their slice.

## What it costs

Nothing at all where it is not wanted. The middleware is not added to the stack
and the collector does not subscribe, so no notification of yours is delivered
anywhere. That is decided once, at boot:

```ruby
config.install = -> { Rails.env.development? || ENV["RES_INSPECTOR"] }
```

The default needs no setting. It installs in development, and anywhere else as
soon as `enabled` says who may look — configuring one without the other would
otherwise leave the tool silently absent.

Where it is installed but a request is refused, the cost is one predicate call
plus a thread-local read per notification.

Pages carry a shell — styles, a badge, a script — a few hundred bytes that do
not grow with how much has been collected. The tree is built only when somebody
opens the panel; a closed one asks for the count alone, and no tree is built at
all.

Collecting is wrapped so that nothing it gets wrong can reach your application.
An unexpected payload costs a skipped entry, reported through `Rails.error`
where your error tracker already listens.

## How it works

Everything comes from instrumentation RailsEventStore already emits — nothing
is added to the core.

`causation_id` in the metadata says which **event** a child came out of. Which
**handler** produced it is not in the metadata at all, since every handler of an
event runs under the same one, so the collector keeps a per-thread stack of what
is currently running. That is also why it subscribes with objects rather than
blocks: it needs the start of each notification, not only the finish.
