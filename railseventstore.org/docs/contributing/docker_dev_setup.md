---
title: Docker-based local development
sidebar_label: Docker setup
---

Running the browser demo or the test suite doesn't require installing Ruby, rbenv/rvm/asdf, or Nix on your machine — `support/docker/Dockerfile` and the `docker-compose*.yml` files next to it do it for you. This is an alternative to the [Nix-based ephemeral database setup](https://github.com/RailsEventStore/rails_event_store/tree/master/support/nix) used on CI (`nix-shell`), not a replacement for it — use whichever you have installed.

As with everything else in this repo, `make` is the entry point. The commands below are `make` targets in `ruby_event_store-browser/Makefile` and `ruby_event_store-active_record/Makefile`; run `make help` in either directory to see them alongside the regular (non-Docker) targets.

## Three compose files

- `support/docker/docker-compose.yml` — the default stack. Just the `app` service, image-baked (no bind mount), no database. `ruby_event_store-browser`'s demo UI seeds itself with ~110 sample events in memory on boot.
- `support/docker/docker-compose.dev.yml` — an overlay for local editing. Always used together with the base file.
- `support/docker/docker-compose.test.yml` — a separate, opt-in stack for running specs/mutation tests against real databases. Not combined with the other two.

### Try the browser demo

```
cd ruby_event_store-browser
make docker-dev
```

Open [http://localhost:9393](http://localhost:9393).

### Edit with live-reload

```
cd ruby_event_store-browser
make docker-dev-watch
```

This bind-mounts the repo into the `app` container and runs rackup under [`entr`](https://eradman.com/entrproject/), which restarts the server whenever a `.rb`, `.ru`, or `.erb` file changes — no image rebuild.

`entr` builds its watch list once, from `find`, at container start. Editing an existing file is picked up immediately; a **newly created** file is not watched until the container restarts:

```
docker compose -f support/docker/docker-compose.yml -f support/docker/docker-compose.dev.yml restart app
```

Still no rebuild needed, just a restart.

### Console

```
cd ruby_event_store-browser
make docker-console
```

Drops you into an `irb` session with the gem loaded and the repo bind-mounted, for ad hoc event publish/read exploration.

### Run tests against real databases

```
cd ruby_event_store-active_record
make docker-test
```

Spins up ephemeral Postgres 18 / MySQL 8.4 (tmpfs-backed, no volumes, bound to `127.0.0.1`), then runs rspec. `make docker-mutate` runs mutant the same way.

Both targets bind-mount the repo, so editing a spec doesn't require a rebuild.

## GEM_DIR

Every leaf stage (`test`, `mutate`, `app`, `console`) bundles and runs against one gem's `Gemfile`, selected by the `GEM_DIR` build arg. It defaults to `ruby_event_store-active_record` in the `Dockerfile`, but each compose file pins whatever makes sense for that service — `docker-compose.yml`'s `app` targets `ruby_event_store-browser`, `docker-compose.test.yml`'s `test`/`mutate` target `ruby_event_store-active_record`.

To target a different gem, invoke `docker compose` directly instead of the `make` target and override the build arg:

```
docker compose -f support/docker/docker-compose.test.yml build --build-arg GEM_DIR=ruby_event_store test
```

## CI coverage

`.github/workflows/docker_dev_setup_test.yml` builds and boots the `app` image and runs `make docker-test` on every change under `support/docker/**` (and the two Makefiles above), so this setup can't silently rot.
