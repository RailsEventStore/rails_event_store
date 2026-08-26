---
title: MCP server
---

`ruby_event_store-mcp` lets an AI assistant explore your event store on its own. It is the companion to the [CLI](./cli/): where the `res` command queries the store from your terminal, the MCP server exposes the same queries as [MCP tools](https://modelcontextprotocol.io/) so your assistant reads the events itself — you ask questions in plain English instead of copy-pasting payloads into the chat.

The server is intentionally **read-only**. The assistant can inspect events, streams, and correlations, but it cannot append, link, or delete. Every tool goes through the public `event_store` API — no SQL, no adapter internals — so it works regardless of the storage adapter underneath.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "ruby_event_store-mcp"
```

That installs the `res-mcp` binary. The binary speaks MCP over **stdio**, launched from your app's root, where — exactly like the `res` CLI — it loads `config/environment.rb` and reads your app's `Rails.configuration.event_store`. There is no HTTP endpoint to mount and nothing to deploy.

## Registering the server with your AI client

Telling your client about the server is a separate, one-time step. Every MCP client takes the same server definition — only the file it goes in changes.

### Claude Code

Drop a `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "res": {
      "command": "bundle",
      "args": ["exec", "res-mcp"]
    }
  }
}
```

(or run `claude mcp add res -- bundle exec res-mcp`). Launched from the project directory, Claude Code runs the server there, so no `cwd` is needed. On the next launch it asks you to trust the project's MCP server — approve it, then run `/mcp` to see `res` connected with its nine tools.

### Claude Desktop

The same block, but with an explicit `cwd` pointing at your app's root, in `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "res": {
      "command": "bundle",
      "args": ["exec", "res-mcp"],
      "cwd": "/path/to/your/rails/app"
    }
  }
}
```

(macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`; Windows: `%APPDATA%\Claude\claude_desktop_config.json`.)

### Other MCP clients

Cursor, Windsurf, Cline and the rest take the same `mcpServers` block in their own config file; VS Code's built-in MCP uses a `servers` key with `"type": "stdio"` instead. The `bundle exec res-mcp` command is the portable part.

## The tools

The server gives the assistant nine read-only tools over your event store. You never call them by name — you ask a question, and the assistant picks the tools it needs (the first call asks your permission; allowlist the `res` server to stop being asked). They cover three kinds of questions:

**Browse streams and events**

- `stream_show` — a stream's event count, version, and first/last event
- `stream_events` — the events in a stream, filterable by type, time, or position
- `event_show` — one event in full, data and metadata
- `event_streams` — every stream a given event belongs to

**Search and summarize**

- `recent` — the most recent events across the whole store ("what just happened?")
- `search` — events anywhere, filtered by type, time range, or stream
- `stats` — total counts and the unique event types present

**Follow a process**

- `aggregate_history` — the full event history of one aggregate instance (e.g. a single `Fulfillment::Order`)
- `trace` — the [causation tree](./correlation-causation/) of everything sharing a correlation ID, so you can see where a multi-step flow stopped

## Ask questions, not commands

Once it is connected you just talk to the assistant — no slash command, no skill. You ask in plain English and it decides which tools to call:

> "What just happened? Show the 20 most recent events."

> "Walk me through the history of Fulfillment::Order f47ac10b-58cc-4372-a567-0e02b2c3d479."

> "Are there any OrderPlaced events from the last hour without a matching OrderConfirmed?"

> "Trace correlation 452fd6f0-e3a2-4716-bc8a-43bbcf2cae61 — where did the process stop?"

The assistant calls `recent`, `aggregate_history`, `search`, or `trace` behind the scenes, reads the results, and reasons over them — no copy-pasting event payloads into the chat, no switching to a Rails console mid-thought.

## See also

Prefer typing the queries yourself? The companion [CLI](./cli/) exposes the same event store as a `res` command in your terminal.
