---
title: Developing RES
---


```
env RAILS_VERSION=5.2.4.1 make -C rails_event_store_active_record reinstall test
```

```
docker-compose run res make -C rails_event_store_active_record reinstall test
```