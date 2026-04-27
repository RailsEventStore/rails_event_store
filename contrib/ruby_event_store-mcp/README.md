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

The server communicates over stdio using the MCP protocol. Configure it in Claude Desktop or Claude Code:

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

## Requirements

- Ruby >= 3.0
- A Rails application with `Rails.configuration.event_store` configured

## Available tools

| Tool | Description |
|---|---|
| `stream_show` | Event count, version, first/last event for a stream |
| `stream_events` | List events in a stream (filter by type, time range, limit) |
| `event_show` | Full event details: data, metadata, timestamps |
| `event_streams` | All streams an event has been published or linked to |
| `search` | Search events by type, time range, or stream |
| `stats` | Total event count and unique event types |
| `trace` | Causation tree for all events sharing a correlation ID |
