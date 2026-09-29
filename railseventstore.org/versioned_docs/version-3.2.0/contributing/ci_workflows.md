---
title: CI workflows
sidebar_label: CI workflows
---

The GitHub Actions workflows in `.github/workflows/*.yml` are **generated**. The source
of truth is a single Ruby script,
[`support/ci/generate`](https://github.com/RailsEventStore/rails_event_store/blob/master/support/ci/generate),
which builds every workflow and writes the YAML.

**Do not hand-edit the generated YAML.** Any manual change is overwritten on the next
regeneration, and CI rejects the drift. Change the script instead.

## Making a change

```sh
# 1. edit support/ci/generate
# 2. regenerate the YAML in place
make generate-workflows
# 3. commit the script AND the regenerated .github/workflows/*.yml together
```

## Drift guard

`make verify-workflows` regenerates the workflows into a temporary directory and diffs
them against the committed `.github/workflows/`. A non-empty diff means the YAML has
drifted from the script, and the command exits non-zero.

The same check runs in CI (`verify_workflows.yml`) on every pull request that touches
`support/ci/**` or `.github/workflows/**`, so a hand-edited workflow fails before it can
be merged. `verify_workflows.yml` is itself hand-written — the generator does not produce
it — and is excluded from the diff.

## What the script produces

Three job flavours per gem, plus a standalone devenv smoke test:

| Builder                                  | Job        | Runs on | Purpose                      |
| ---------------------------------------- | ---------- | ------- | ---------------------------- |
| `release_test` / `contrib_test`          | `test`     | ubuntu  | unit tests across the matrix |
| `release_mutate` / `contrib_mutate`      | `mutate`   | macos   | incremental mutation testing |
| `release_coverage` / `contrib_coverage`  | `coverage` | macos   | full mutation coverage       |

`release_*` builders are for the gems released from the repository root; `contrib_*` are
for the gems under `contrib/`. The full list lives in the `workflows` method at the top of
the script.

## The matrix DSL

Each job's `strategy.matrix.include` is built from small combinators (backed by the
[`szczupac`](https://rubygems.org/gems/szczupac) gem):

- **`axis(name, *values)`** — one dimension, e.g. `ruby_version("ruby-4.0", "ruby-3.4")`.
  Named helpers wrap it: `ruby_version`, `bundle_gemfile`, `database_url`, `data_type`.

- **`sparse(*axes)`** — a **sparse** matrix. It varies one axis at a time against the
  others' first (baseline) value. This is **not** a full cartesian product:

  ```ruby
  sparse(ruby_version("4.0", "3.4", "3.3"), bundle_gemfile("G", "R1", "R2"))
  # => 5 rows, not 9:
  #   {ruby 4.0, G} {ruby 3.4, G} {ruby 3.3, G}   # ruby varies at the baseline gemfile
  #   {ruby 4.0, R1} {ruby 4.0, R2}               # gemfile varies at the baseline ruby
  ```

  It keeps the matrix small while exercising every value at least once. `sparse` also
  composes: passing already-built row lists as "axes" sparsely combines whole groups (see
  the `ruby_event_store-active_record` workflow).

- **`union(*groups)`** — set union (with dedup) of row lists, for stitching several
  `sparse` blocks into one matrix.

Need the **full cartesian product** instead? Use `Szczupac.permutation` in place of
`sparse`.

## Output directory override

By default the script writes to `.github/workflows/`. Set `WORKFLOWS_ROOT` to redirect it
(this is how `make verify-workflows` generates into a temporary directory):

```sh
WORKFLOWS_ROOT=/tmp/wf ruby support/ci/generate
```
