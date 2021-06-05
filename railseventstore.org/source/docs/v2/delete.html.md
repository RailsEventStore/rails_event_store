---
title: Deleting stream
---

You can permanently delete all events from a specific stream. Use this wisely.

```ruby
stream_name = "product_1"
client.delete_stream(stream_name)
```

NOTE: All events from the stream remain intact but they are no longer linked to the stream.
