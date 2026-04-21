---
title: Deleting stream
---

You can permanently delete all events from a specific stream.

```ruby
stream_name = "product_1"
client.delete_stream(stream_name)
```

When you do it, events remain intact but they are no longer linked to the stream.
