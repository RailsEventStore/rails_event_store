# ruby_event_store-mcp

Model Context Protocol (MCP) server for [RubyEventStore](https://railseventstore.org). Exposes your event store as AI tools so Claude (and other MCP clients) can inspect streams, events, and causal relationships directly.

## Installation

Add to your Rails app's `Gemfile`:

```ruby
gem "ruby_event_store-mcp"
```

## Usage

Run from the root of your Rails application:

```bash
bundle exec res-mcp
```

The server communicates over stdio using the MCP protocol. Installing the gem only provides the `res-mcp` binary — you still have to register it with your MCP client. Every client takes the same server definition; only the file it lives in differs.

### Claude Code

Add a `.mcp.json` to your project root (or run `claude mcp add res -- bundle exec res-mcp`):

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

Launched from the project directory, Claude Code runs the server there, so no `cwd` is needed. On the next launch Claude Code asks you to trust the server — approve it, then run `/mcp` to confirm `res` is connected with its tools.

### Claude Desktop

Add the same block with an explicit `cwd` pointing at your app's root, in `claude_desktop_config.json`:

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

Config file locations:

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

### Other MCP clients

Cursor, Windsurf, Cline and others take the same `mcpServers` block in their own config file. VS Code's built-in MCP support uses a `servers` key with `"type": "stdio"` instead. The `bundle exec res-mcp` command is the portable part.

## Requirements

- Ruby >= 3.0
- A Rails application with `Rails.configuration.event_store` configured

## Available tools

| Tool                | Description                                                      |
|---------------------|------------------------------------------------------------------|
| `recent`            | Most recent events across all streams (default: 20, newest first)|
| `stream_show`       | Event count, version, first/last event for a stream              |
| `stream_events`     | List events in a stream (filter by type, time range, limit)      |
| `event_show`        | Full event details: data, metadata, timestamps                   |
| `event_streams`     | All streams an event has been published or linked to             |
| `aggregate_history` | Full event history of an aggregate instance by type and ID       |
| `search`            | Search events by type, time range, or stream                     |
| `stats`             | Total event count and unique event types                         |
| `trace`             | Causation tree for all events sharing a correlation ID           |
