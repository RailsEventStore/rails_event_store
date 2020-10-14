---
title: Deleting stream
---

You can permanently delete all events from a specific stream. Use this wisely.

```ruby
stream_name = "product_1"
client.delete_stream(stream_name)
```
