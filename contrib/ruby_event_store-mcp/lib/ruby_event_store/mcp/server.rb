# frozen_string_literal: true

require "json"

module RubyEventStore
  module MCP
    class Server
      PROTOCOL_VERSION = "2024-11-05"

      attr_reader :event_store, :name, :version, :tools

      def initialize(event_store:, name: "ruby-event-store", version: VERSION)
        @event_store = event_store
        @name = name
        @version = version
        @tools = []
      end

      def register(tool)
        tools << tool
        self
      end

      def start(input: $stdin, output: $stdout)
        output.sync = true
        input.each_line do |line|
          request = JSON.parse(line.strip)
          response = handle(request)
          output.puts(JSON.generate(response)) if response
        end
      end

      private

      def handle(request)
        id = request["id"]
        method = request["method"]

        case method
        when "initialize"
          result = {
            protocolVersion: PROTOCOL_VERSION,
            capabilities: { tools: {} },
            serverInfo: { name: name, version: version }
          }
          jsonrpc_result(id, result)
        when "notifications/initialized"
          nil
        when "tools/list"
          jsonrpc_result(id, { tools: tools.map(&:schema) })
        when "tools/call"
          call_tool(id, request["params"])
        when "ping"
          jsonrpc_result(id, {})
        else
          jsonrpc_error(id, -32601, "Method not found: #{method}")
        end
      rescue => e
        jsonrpc_error(request["id"], -32603, e.message)
      end

      def call_tool(id, params)
        tool_name = params["name"]
        arguments = params["arguments"] || {}
        tool = tools.find { |t| t.name == tool_name }
        return jsonrpc_result(id, { content: [{ type: "text", text: "Unknown tool: #{tool_name}" }], isError: true }) unless tool

        result = tool.call(event_store, arguments)
        jsonrpc_result(id, { content: [{ type: "text", text: result }] })
      rescue => e
        jsonrpc_result(id, { content: [{ type: "text", text: "Error: #{e.message}" }], isError: true })
      end

      def jsonrpc_result(id, result)
        { jsonrpc: "2.0", id: id, result: result }
      end

      def jsonrpc_error(id, code, message)
        { jsonrpc: "2.0", id: id, error: { code: code, message: message } }
      end
    end
  end
end
