# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp/server"

module RubyEventStore
  module MCP
    ::RSpec.describe Server do
      let(:event_store) { RubyEventStore::Client.new }
      let(:server) { Server.new(event_store: event_store, name: "test-server", version: "0.0.1") }

      def call(server, request)
        input = StringIO.new(JSON.generate(request) + "\n")
        output = StringIO.new
        server.start(input: input, output: output)
        output.rewind
        lines = output.read.split("\n").reject(&:empty?)
        lines.map { |l| JSON.parse(l) }
      end

      describe "initialize" do
        it "returns server info and capabilities" do
          responses = call(server, { jsonrpc: "2.0", id: 1, method: "initialize", params: {} })
          result = responses.first["result"]
          expect(result["protocolVersion"]).to eq(Server::PROTOCOL_VERSION)
          expect(result["serverInfo"]["name"]).to eq("test-server")
          expect(result["capabilities"]).to have_key("tools")
        end
      end

      describe "notifications/initialized" do
        it "produces no response" do
          responses = call(server, { jsonrpc: "2.0", method: "notifications/initialized" })
          expect(responses).to be_empty
        end
      end

      describe "ping" do
        it "returns empty result" do
          responses = call(server, { jsonrpc: "2.0", id: 2, method: "ping" })
          expect(responses.first["result"]).to eq({})
        end
      end

      describe "tools/list" do
        it "returns empty list when no tools registered" do
          responses = call(server, { jsonrpc: "2.0", id: 3, method: "tools/list" })
          expect(responses.first["result"]["tools"]).to eq([])
        end

        it "returns registered tool schemas" do
          tool = instance_double("tool", name: "my_tool", schema: { name: "my_tool", description: "desc", inputSchema: {} })
          server.register(tool)
          responses = call(server, { jsonrpc: "2.0", id: 3, method: "tools/list" })
          expect(responses.first["result"]["tools"].first["name"]).to eq("my_tool")
        end
      end

      describe "tools/call" do
        it "returns isError result for unknown tool" do
          responses = call(server, { jsonrpc: "2.0", id: 4, method: "tools/call", params: { "name" => "unknown" } })
          expect(responses.first["result"]["isError"]).to be(true)
          expect(responses.first["result"]["content"].first["text"]).to include("Unknown tool")
        end

        it "calls the matching tool and returns its output" do
          tool = instance_double("tool", name: "my_tool")
          allow(tool).to receive(:call).with(event_store, {}).and_return("hello")
          server.register(tool)
          responses = call(server, { jsonrpc: "2.0", id: 4, method: "tools/call", params: { "name" => "my_tool", "arguments" => {} } })
          expect(responses.first["result"]["content"].first["text"]).to eq("hello")
        end
      end

      describe "unknown method" do
        it "returns method not found error" do
          responses = call(server, { jsonrpc: "2.0", id: 5, method: "unknown/method" })
          expect(responses.first["error"]["code"]).to eq(-32601)
        end
      end
    end
  end
end
