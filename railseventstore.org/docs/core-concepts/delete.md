---
title: Deleting stream
---

You can permanently delete all events from a specific stream.

```ruby
stream_name = "product_1"
client.delete_stream(stream_name)
```

When you do it, events remain intact but they are no longer linked to the stream.

This is immediate and cannot be undone. If you need to hide a stream from reads, keep the possibility to show it again, close it for writes or set up retention, see [Stream deletion and retention](./stream-deletion-and-retention).
