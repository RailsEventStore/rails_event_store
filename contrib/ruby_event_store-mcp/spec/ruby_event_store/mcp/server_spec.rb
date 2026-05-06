# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp/server"
require "ruby_event_store/mcp/tools/stream_show"
require "ruby_event_store/mcp/tools/event_show"
require "ruby_event_store/mcp/tools/stats"

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
        it "returns protocol version" do
          responses = call(server, { jsonrpc: "2.0", id: 1, method: "initialize", params: {} })
          expect(responses.first["result"]["protocolVersion"]).to eq(Server::PROTOCOL_VERSION)
        end

        it "returns server name and version" do
          responses = call(server, { jsonrpc: "2.0", id: 1, method: "initialize", params: {} })
          info = responses.first["result"]["serverInfo"]
          expect(info["name"]).to eq("test-server")
          expect(info["version"]).to eq("0.0.1")
        end

        it "returns tools capability as object" do
          responses = call(server, { jsonrpc: "2.0", id: 1, method: "initialize", params: {} })
          expect(responses.first["result"]["capabilities"]["tools"]).to be_a(Hash)
        end

        it "echoes back the request id" do
          responses = call(server, { jsonrpc: "2.0", id: 42, method: "initialize", params: {} })
          expect(responses.first["id"]).to eq(42)
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
          server.register(Tools::StreamShow.new)
          responses = call(server, { jsonrpc: "2.0", id: 3, method: "tools/list" })
          expect(responses.first["result"]["tools"].first["name"]).to eq("stream_show")
        end

        it "echoes back the request id" do
          responses = call(server, { jsonrpc: "2.0", id: 99, method: "tools/list" })
          expect(responses.first["id"]).to eq(99)
        end
      end

      describe "tools/call" do
        it "returns isError result for unknown tool" do
          responses = call(server, { jsonrpc: "2.0", id: 4, method: "tools/call", params: { "name" => "unknown" } })
          expect(responses.first["result"]["isError"]).to be(true)
          expect(responses.first["result"]["content"].first["text"]).to include("Unknown tool")
        end

        it "calls the matching tool and returns its output" do
          event_store.publish(RubyEventStore::Event.new, stream_name: "test")
          server.register(Tools::StreamShow.new)
          responses = call(server, { jsonrpc: "2.0", id: 4, method: "tools/call", params: { "name" => "stream_show", "arguments" => { "stream_name" => "test" } } })
          expect(responses.first["result"]["content"].first["text"]).to include("Events:  1")
        end

        it "defaults arguments to empty hash allowing tools to succeed without arguments" do
          server.register(Tools::Stats.new)
          responses = call(server, { jsonrpc: "2.0", id: 4, method: "tools/call", params: { "name" => "stats" } })
          expect(responses.first["result"]["isError"]).to be_nil
          expect(responses.first["result"]["content"].first["text"]).to include("Events:")
        end

        it "finds tool by name not by position" do
          server.register(Tools::StreamShow.new)
          server.register(Tools::Stats.new)
          responses = call(server, { jsonrpc: "2.0", id: 4, method: "tools/call", params: { "name" => "stats" } })
          expect(responses.first["result"]["content"].first["text"]).to include("Events:")
        end

        it "returns isError result when tool raises" do
          server.register(Tools::EventShow.new)
          responses = call(server, { jsonrpc: "2.0", id: 4, method: "tools/call", params: { "name" => "event_show", "arguments" => { "event_id" => SecureRandom.uuid } } })
          expect(responses.first["result"]["isError"]).to be(true)
          expect(responses.first["result"]["content"].first["text"]).to include("Error:")
        end

        it "unknown tool error content has type text" do
          responses = call(server, { jsonrpc: "2.0", id: 4, method: "tools/call", params: { "name" => "unknown" } })
          expect(responses.first["result"]["content"].first["type"]).to eq("text")
        end

        it "result content has type text" do
          server.register(Tools::StreamShow.new)
          responses = call(server, { jsonrpc: "2.0", id: 4, method: "tools/call", params: { "name" => "stream_show", "arguments" => { "stream_name" => "test" } } })
          expect(responses.first["result"]["content"].first["type"]).to eq("text")
        end

        it "unknown tool error echoes request id" do
          responses = call(server, { jsonrpc: "2.0", id: 55, method: "tools/call", params: { "name" => "unknown" } })
          expect(responses.first["id"]).to eq(55)
        end

        it "tool call echoes request id" do
          server.register(Tools::Stats.new)
          responses = call(server, { jsonrpc: "2.0", id: 66, method: "tools/call", params: { "name" => "stats" } })
          expect(responses.first["id"]).to eq(66)
        end
      end

      describe "unknown method" do
        it "returns method not found error code" do
          responses = call(server, { jsonrpc: "2.0", id: 5, method: "unknown/method" })
          expect(responses.first["error"]["code"]).to eq(-32601)
        end

        it "includes method name in error message" do
          responses = call(server, { jsonrpc: "2.0", id: 5, method: "unknown/method" })
          expect(responses.first["error"]["message"]).to include("unknown/method")
        end

        it "echoes back the request id" do
          responses = call(server, { jsonrpc: "2.0", id: 77, method: "unknown/method" })
          expect(responses.first["id"]).to eq(77)
        end
      end

      describe "#start" do
        it "sets output to sync mode" do
          output = StringIO.new
          expect(output).to receive(:sync=).with(true)
          input = StringIO.new(JSON.generate({ jsonrpc: "2.0", id: 1, method: "ping" }) + "\n")
          server.start(input: input, output: output)
        end

        it "handles multiple requests in sequence" do
          input = StringIO.new(
            JSON.generate({ jsonrpc: "2.0", id: 1, method: "ping" }) + "\n" +
            JSON.generate({ jsonrpc: "2.0", id: 2, method: "ping" }) + "\n"
          )
          output = StringIO.new
          server.start(input: input, output: output)
          output.rewind
          responses = output.read.split("\n").map { |l| JSON.parse(l) }
          expect(responses.size).to eq(2)
          expect(responses.map { |r| r["id"] }).to eq([1, 2])
        end

        it "skips output for notifications" do
          input = StringIO.new(
            JSON.generate({ jsonrpc: "2.0", method: "notifications/initialized" }) + "\n" +
            JSON.generate({ jsonrpc: "2.0", id: 1, method: "ping" }) + "\n"
          )
          output = StringIO.new
          server.start(input: input, output: output)
          output.rewind
          responses = output.read.split("\n").map { |l| JSON.parse(l) }
          expect(responses.size).to eq(1)
          expect(responses.first["id"]).to eq(1)
        end
      end

      describe "#register" do
        it "returns self to allow chaining" do
          expect(server.register(Tools::StreamShow.new)).to eq(server)
        end

        it "adds tool to tools list" do
          expect { server.register(Tools::StreamShow.new) }.to change { server.tools.size }.by(1)
        end

        it "adds the exact tool object to the list" do
          tool = Tools::StreamShow.new
          server.register(tool)
          expect(server.tools.last.name).to eq("stream_show")
        end
      end

      describe "#initialize" do
        it "defaults name to ruby-event-store" do
          s = Server.new(event_store: event_store)
          expect(s.name).to eq("ruby-event-store")
        end

        it "defaults version to MCP::VERSION" do
          s = Server.new(event_store: event_store)
          expect(s.version).to eq(MCP::VERSION)
        end

        it "stores given event_store" do
          s = Server.new(event_store: event_store)
          expect(s.event_store).to equal(event_store)
        end

        it "starts with empty tools list" do
          s = Server.new(event_store: event_store)
          expect(s.tools).to eq([])
        end
      end

      describe "#jsonrpc_result" do
        it "includes jsonrpc 2.0 version string" do
          responses = call(server, { jsonrpc: "2.0", id: 1, method: "ping" })
          expect(responses.first["jsonrpc"]).to eq("2.0")
        end

        it "returns jsonrpc 2.0, given id, and given result" do
          response = server.send(:jsonrpc_result, 42, { foo: "bar" })
          expect(response[:jsonrpc]).to eq("2.0")
          expect(response[:id]).to eq(42)
          expect(response[:result]).to eq({ foo: "bar" })
        end

        it "has exactly jsonrpc, id, result keys" do
          response = server.send(:jsonrpc_result, 1, {})
          expect(response.keys).to contain_exactly(:jsonrpc, :id, :result)
        end
      end

      describe "#jsonrpc_error" do
        it "includes jsonrpc 2.0 version string" do
          responses = call(server, { jsonrpc: "2.0", id: 1, method: "unknown/method" })
          expect(responses.first["jsonrpc"]).to eq("2.0")
        end

        it "returns jsonrpc 2.0, given id, code, and message in error" do
          response = server.send(:jsonrpc_error, 42, -32601, "not found")
          expect(response[:jsonrpc]).to eq("2.0")
          expect(response[:id]).to eq(42)
          expect(response[:error][:code]).to eq(-32601)
          expect(response[:error][:message]).to eq("not found")
        end

        it "has exactly jsonrpc, id, error keys" do
          response = server.send(:jsonrpc_error, 1, -32601, "msg")
          expect(response.keys).to contain_exactly(:jsonrpc, :id, :error)
        end
      end

      describe "#handle rescue" do
        class BrokenSchemaTool
          def name = "broken_tool"
          def schema = raise "broken_schema_error"
          def call(_, _) = "ok"
        end

        it "returns nil id in rescue response when request has no id field" do
          server.register(BrokenSchemaTool.new)
          response = server.send(:handle, { "method" => "tools/list" })
          expect(response[:id]).to be_nil
          expect(response[:error][:code]).to eq(-32603)
        end

        it "returns -32603 error when an internal exception is raised" do
          server.register(BrokenSchemaTool.new)
          responses = call(server, { jsonrpc: "2.0", id: 7, method: "tools/list" })
          expect(responses.first["error"]["code"]).to eq(-32603)
        end

        it "includes exception message in -32603 error" do
          server.register(BrokenSchemaTool.new)
          responses = call(server, { jsonrpc: "2.0", id: 7, method: "tools/list" })
          expect(responses.first["error"]["message"]).to include("broken_schema_error")
        end

        it "echoes request id in -32603 error" do
          server.register(BrokenSchemaTool.new)
          responses = call(server, { jsonrpc: "2.0", id: 42, method: "tools/list" })
          expect(responses.first["id"]).to eq(42)
        end

        it "includes jsonrpc 2.0 in -32603 error" do
          server.register(BrokenSchemaTool.new)
          responses = call(server, { jsonrpc: "2.0", id: 7, method: "tools/list" })
          expect(responses.first["jsonrpc"]).to eq("2.0")
        end
      end

      describe "#handle (direct)" do
        def handle(request)
          server.send(:handle, request)
        end

        it "returns id from request" do
          response = handle({ "id" => 42, "method" => "ping" })
          expect(response[:id]).to eq(42)
        end

        it "returns nil for notifications/initialized" do
          response = handle({ "method" => "notifications/initialized" })
          expect(response).to be_nil
        end

        it "returns empty hash result for ping" do
          response = handle({ "id" => 1, "method" => "ping" })
          expect(response[:result]).to eq({})
        end

        it "returns protocol version in initialize result" do
          response = handle({ "id" => 1, "method" => "initialize", "params" => {} })
          expect(response[:result][:protocolVersion]).to eq(Server::PROTOCOL_VERSION)
        end

        it "returns tools capability as hash in initialize" do
          response = handle({ "id" => 1, "method" => "initialize", "params" => {} })
          expect(response[:result][:capabilities][:tools]).to be_a(Hash)
        end

        it "returns server name in initialize serverInfo" do
          response = handle({ "id" => 1, "method" => "initialize", "params" => {} })
          expect(response[:result][:serverInfo][:name]).to eq("test-server")
        end

        it "returns server version in initialize serverInfo" do
          response = handle({ "id" => 1, "method" => "initialize", "params" => {} })
          expect(response[:result][:serverInfo][:version]).to eq("0.0.1")
        end

        it "returns tools list for tools/list" do
          server.register(Tools::Stats.new)
          response = handle({ "id" => 1, "method" => "tools/list" })
          expect(response[:result][:tools].map { |t| t[:name] }).to include("stats")
        end

        it "returns -32601 error for unknown method" do
          response = handle({ "id" => 1, "method" => "unknown/xyz" })
          expect(response[:error][:code]).to eq(-32601)
          expect(response[:error][:message]).to include("unknown/xyz")
        end

        it "returns -32603 and uses request id from request hash on internal error" do
          server.register(BrokenSchemaTool.new)
          response = handle({ "id" => 99, "method" => "tools/list" })
          expect(response[:error][:code]).to eq(-32603)
          expect(response[:id]).to eq(99)
          expect(response[:error][:message]).to include("broken_schema_error")
        end

        it "returns -32601 when method key is absent" do
          response = handle({ "id" => 1 })
          expect(response[:error][:code]).to eq(-32601)
        end
      end

      describe "#start strip" do
        it "strips leading whitespace from lines before parsing" do
          input = StringIO.new("  " + JSON.generate({ jsonrpc: "2.0", id: 1, method: "ping" }) + "\n")
          output = StringIO.new
          server.start(input: input, output: output)
          output.rewind
          responses = output.read.split("\n").map { |l| JSON.parse(l) }
          expect(responses.first["id"]).to eq(1)
        end

        it "strips trailing whitespace from lines before parsing" do
          input = StringIO.new(JSON.generate({ jsonrpc: "2.0", id: 1, method: "ping" }) + "  \n")
          output = StringIO.new
          server.start(input: input, output: output)
          output.rewind
          responses = output.read.split("\n").map { |l| JSON.parse(l) }
          expect(responses.first["id"]).to eq(1)
        end
      end

      describe "#tools/call details" do
        it "includes tool name in unknown tool error message" do
          responses = call(server, { jsonrpc: "2.0", id: 4, method: "tools/call", params: { "name" => "specific_unknown_tool" } })
          expect(responses.first["result"]["content"].first["text"]).to include("specific_unknown_tool")
        end

        it "includes exception message text in tool error response" do
          server.register(Tools::EventShow.new)
          responses = call(server, { jsonrpc: "2.0", id: 4, method: "tools/call", params: { "name" => "event_show", "arguments" => { "event_id" => SecureRandom.uuid } } })
          text = responses.first["result"]["content"].first["text"]
          expect(text).to match(/Error: .+/)
        end

        it "error result content has type text" do
          server.register(Tools::EventShow.new)
          responses = call(server, { jsonrpc: "2.0", id: 4, method: "tools/call", params: { "name" => "event_show", "arguments" => { "event_id" => SecureRandom.uuid } } })
          expect(responses.first["result"]["content"].first["type"]).to eq("text")
        end
      end

      describe "#call_tool (direct)" do
        class ErrorWithDistinctToS < StandardError
          def to_s = "to_s_value"
          def message = "message_value"
        end

        class ToSOverridingTool
          def name = "tos_tool"
          def schema = { name: "tos_tool", description: "test", inputSchema: { type: "object", properties: {}, required: [] } }
          def call(_, _) = raise ErrorWithDistinctToS
        end

        def call_tool(id, params)
          server.send(:call_tool, id, params)
        end

        it "uses exception message (not to_s) in error text" do
          server.register(ToSOverridingTool.new)
          result = call_tool(1, { "name" => "tos_tool" })
          expect(result[:result][:content].first[:text]).to eq("Error: message_value")
        end

        it "returns unknown tool error when name key is absent" do
          result = call_tool(1, { "arguments" => {} })
          expect(result[:result][:content].first[:text]).to include("Unknown tool")
          expect(result[:result][:isError]).to be(true)
        end

        it "returns isError for unknown tool" do
          result = call_tool(1, { "name" => "nonexistent" })
          expect(result[:result][:isError]).to be(true)
        end

        it "includes tool name in unknown tool error text" do
          result = call_tool(1, { "name" => "specific_unknown_xyz" })
          expect(result[:result][:content].first[:text]).to include("specific_unknown_xyz")
        end

        it "finds tool by name not by position" do
          server.register(Tools::StreamShow.new)
          server.register(Tools::Stats.new)
          result = call_tool(1, { "name" => "stats" })
          expect(result[:result][:content].first[:text]).to include("Events:")
        end

        it "returns correct id in error response when tool raises" do
          server.register(Tools::EventShow.new)
          result = call_tool(42, { "name" => "event_show", "arguments" => { "event_id" => SecureRandom.uuid } })
          expect(result[:result][:isError]).to be(true)
          expect(result[:id]).to eq(42)
        end

        it "error content type is text" do
          server.register(Tools::EventShow.new)
          result = call_tool(1, { "name" => "event_show", "arguments" => { "event_id" => SecureRandom.uuid } })
          expect(result[:result][:content].first[:type]).to eq("text")
        end

        it "error text includes the exception message" do
          server.register(Tools::EventShow.new)
          result = call_tool(1, { "name" => "event_show", "arguments" => { "event_id" => SecureRandom.uuid } })
          text = result[:result][:content].first[:text]
          expect(text).to match(/Error: .+/)
        end

        it "passes arguments to tool" do
          event_store.publish(RubyEventStore::Event.new, stream_name: "test")
          server.register(Tools::StreamShow.new)
          result = call_tool(1, { "name" => "stream_show", "arguments" => { "stream_name" => "test" } })
          expect(result[:result][:content].first[:text]).to include("Stream:")
        end

        it "returns correct id for successful call" do
          server.register(Tools::Stats.new)
          result = call_tool(55, { "name" => "stats" })
          expect(result[:id]).to eq(55)
        end

        it "success content type is text" do
          server.register(Tools::Stats.new)
          result = call_tool(1, { "name" => "stats" })
          expect(result[:result][:content].first[:type]).to eq("text")
        end

        it "finds non-last tool by name" do
          server.register(Tools::Stats.new)
          server.register(Tools::StreamShow.new)
          result = call_tool(1, { "name" => "stats" })
          expect(result[:result][:content].first[:text]).to include("Events:")
        end

        it "returns correct id for unknown tool" do
          result = call_tool(55, { "name" => "nonexistent" })
          expect(result[:id]).to eq(55)
        end

        it "unknown tool content type is text" do
          result = call_tool(1, { "name" => "nonexistent" })
          expect(result[:result][:content].first[:type]).to eq("text")
        end
      end

      describe "#handle tools/call routing (direct)" do
        def handle(request)
          server.send(:handle, request)
        end

        it "returns id from request for initialize" do
          response = handle({ "id" => 42, "method" => "initialize", "params" => {} })
          expect(response[:id]).to eq(42)
        end

        it "returns id from request for tools/list" do
          response = handle({ "id" => 77, "method" => "tools/list" })
          expect(response[:id]).to eq(77)
        end

        it "routes tools/call using params name to find the right tool" do
          server.register(Tools::Stats.new)
          response = handle({ "id" => 1, "method" => "tools/call", "params" => { "name" => "stats" } })
          expect(response[:result][:content].first[:text]).to include("Events:")
        end

        it "passes params to call_tool so tool arguments are used" do
          event_store.publish(RubyEventStore::Event.new, stream_name: "x")
          server.register(Tools::StreamShow.new)
          response = handle({ "id" => 1, "method" => "tools/call", "params" => { "name" => "stream_show", "arguments" => { "stream_name" => "x" } } })
          expect(response[:result][:content].first[:text]).to include("Events:")
        end

        it "returns id from tools/call response" do
          server.register(Tools::Stats.new)
          response = handle({ "id" => 55, "method" => "tools/call", "params" => { "name" => "stats" } })
          expect(response[:id]).to eq(55)
        end

        it "returns unknown method error with correct id" do
          response = handle({ "id" => 99, "method" => "some/unknown" })
          expect(response[:id]).to eq(99)
        end

        it "returns result (not jsonrpc error) when params key is absent from tools/call" do
          response = handle({ "id" => 1, "method" => "tools/call" })
          expect(response).to have_key(:result)
          expect(response).not_to have_key(:error)
        end
      end
    end
  end
end
