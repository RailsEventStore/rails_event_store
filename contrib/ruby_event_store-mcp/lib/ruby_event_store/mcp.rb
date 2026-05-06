# frozen_string_literal: true

require_relative "mcp/version"
require_relative "mcp/read_events"
require_relative "mcp/server"
require_relative "mcp/tools/stream_show"
require_relative "mcp/tools/stream_events"
require_relative "mcp/tools/event_show"
require_relative "mcp/tools/event_streams"
require_relative "mcp/tools/search"
require_relative "mcp/tools/stats"
require_relative "mcp/tools/trace"
require_relative "mcp/tools/aggregate_history"

module RubyEventStore
  module MCP
    def self.server(event_store)
      Server
        .new(event_store: event_store)
        .register(Tools::StreamShow.new)
        .register(Tools::StreamEvents.new)
        .register(Tools::EventShow.new)
        .register(Tools::EventStreams.new)
        .register(Tools::Search.new)
        .register(Tools::Stats.new)
        .register(Tools::Trace.new)
        .register(Tools::AggregateHistory.new)
    end
  end
end
