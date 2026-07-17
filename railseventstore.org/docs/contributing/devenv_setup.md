---
title: Local development with devenv
sidebar_label: devenv setup
---

Contributing to Rails Event Store doesn't require hand-installing Ruby (rbenv/rvm/asdf),
Postgres, MySQL or Redis on your machine. This repository ships a [devenv](https://devenv.sh)
configuration (`devenv.nix` / `devenv.yaml`) that provisions the whole toolchain — the same
Ruby CI runs on, plus databases on the exact ports the CI matrix uses.

This builds on the Nix tooling the project already relies on: CI runs the database-backed
suites inside `nix-shell` using the ephemeral database definitions under `support/nix/`, and
pushes build artifacts to the `railseventstore` [Cachix](https://cachix.org) cache. devenv is
the local-development front end to that same world.

As everywhere else in this repo, `make` stays the entry point — devenv only provides the
environment the existing `make` targets run in.

## One-time setup

Install [Nix](https://nixos.org/download) and [devenv](https://devenv.sh/getting-started/).
Then, from the repository root:

```
devenv shell
```

The first run builds/downloads the toolchain (Cachix makes this fast). You land in a shell
with the right Ruby, bundler and native libraries for the `pg`, `mysql2` and `sqlite3` gems.

## Databases

Start the databases (Postgres 14 + 18, MySQL 8.4, Redis) as background processes:

```
devenv up
```

They listen on the same host/port pairs as `support/ci/generate`, so a `DATABASE_URL`
copied from any CI matrix cell works verbatim:

| Engine      | DATABASE_URL                                                 |
| ----------- | ------------------------------------------------------------ |
| Postgres 14 | `postgres://postgres:secret@localhost:10014/rails_event_store` |
| Postgres 18 | `postgres://postgres:secret@localhost:10018/rails_event_store` |
| MySQL 8.4   | `mysql2://root:secret@127.0.0.1:10084/rails_event_store`       |
| MySQL 9.7   | `mysql2://root:secret@127.0.0.1:10097/rails_event_store`       |
| Redis       | `$REDIS_URL` (unix socket, exported in the shell)             |

> MySQL 9.7 (CI's `mysql_9_7`) is the one version nixpkgs can't provide (no 9.x build), so it
> runs from a `mysql:9.7` container instead of a native process. It starts automatically when a
> docker-compatible CLI (Docker, OrbStack, or an Apple `container` docker shim) is on `PATH`;
> without one, `devenv up` simply skips it and everything else still works natively.

## Running the suites

Inside the devenv shell, use the regular `make` targets:

```
make test-ruby_event_store                 # no database needed
make test-ruby_event_store-active_record   # against Postgres 18 by default
```

To reproduce a specific CI matrix cell, use `res-cell`, which maps a short database
name to the CI `DATABASE_URL` and sets `DATA_TYPE` for you:

```
res-cell pg14 jsonb make test-ruby_event_store-active_record
```

Databases are `sqlite`, `pg14`, `pg18`, `mysql84`, `mysql97`. Or set the environment
variables by hand if you prefer:

```
DATABASE_URL=postgres://postgres:secret@localhost:10014/rails_event_store \
  DATA_TYPE=jsonb make test-ruby_event_store-active_record
```

Mutation testing works the same way:

```
make mutate-ruby_event_store-active_record
```

### Other Ruby versions

The shell's default Ruby is 4.0 (CI's primary cell). To reproduce a 3.3 or 3.4 cell, prefix
the command — each version keeps its own gem home so native extensions never clash:

```
res-ruby-3.4 make test-ruby_event_store-active_record
```

It composes with `res-cell` to pin both axes at once:

```
res-ruby-3.4 res-cell pg14 jsonb make test-ruby_event_store-active_record
```

### Browser demo

```
make -C ruby_event_store-browser dev
```

Serves the standalone browser, seeded with sample events, at
[http://localhost:9393](http://localhost:9393).

## CI coverage

`.github/workflows/devenv_setup_test.yml` boots the databases through devenv and runs a
database-backed and a database-less suite on every change to `devenv.nix` / `devenv.yaml`, so
this setup can't silently rot.
