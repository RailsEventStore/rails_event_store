# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp"

module RubyEventStore
  module MCP
    class OrderPlaced < RubyEventStore::Event; end

    ::RSpec.describe "MCP integration" do
      let(:event_store) { RubyEventStore::Client.new }
      let(:server) { MCP.server(event_store) }

      def call(server, *requests)
        input = StringIO.new(requests.map { |r| JSON.generate(r) }.join("\n") + "\n")
        output = StringIO.new
        server.start(input: input, output: output)
        output.rewind
        output.read.split("\n").map { |l| JSON.parse(l) }
      end

      def tool_call(tool_name, arguments = {})
        { jsonrpc: "2.0", id: 1, method: "tools/call", params: { "name" => tool_name, "arguments" => arguments } }
      end

      it "completes initialize handshake" do
        responses = call(server, { jsonrpc: "2.0", id: 1, method: "initialize", params: {} })
        expect(responses.first["result"]["protocolVersion"]).to eq(Server::PROTOCOL_VERSION)
      end

      it "lists all 9 tools" do
        responses = call(server, { jsonrpc: "2.0", id: 1, method: "tools/list" })
        names = responses.first["result"]["tools"].map { |t| t["name"] }
        expect(names).to contain_exactly(
          "stream_show", "stream_events", "event_show",
          "event_streams", "search", "stats", "trace", "aggregate_history", "recent"
        )
      end

      it "stream_show returns stream info" do
        event_store.publish(OrderPlaced.new, stream_name: "Order$1")
        responses = call(server, tool_call("stream_show", "stream_name" => "Order$1"))
        expect(responses.first["result"]["content"].first["text"]).to include("Events:  1")
      end

      it "stream_events lists events" do
        event_store.publish(OrderPlaced.new, stream_name: "Order$1")
        responses = call(server, tool_call("stream_events", "stream_name" => "Order$1"))
        expect(responses.first["result"]["content"].first["text"]).to include("OrderPlaced")
      end

      it "event_show returns event details" do
        event = OrderPlaced.new(data: { amount: 100 })
        event_store.publish(event, stream_name: "Order$1")
        responses = call(server, tool_call("event_show", "event_id" => event.event_id))
        text = responses.first["result"]["content"].first["text"]
        expect(text).to include("OrderPlaced")
        expect(text).to include("amount")
      end

      it "event_streams lists streams for event" do
        event = OrderPlaced.new
        event_store.publish(event, stream_name: "Order$1")
        responses = call(server, tool_call("event_streams", "event_id" => event.event_id))
        expect(responses.first["result"]["content"].first["text"]).to include("Order$1")
      end

      it "search finds events" do
        event_store.publish(OrderPlaced.new, stream_name: "Order$1")
        responses = call(server, tool_call("search"))
        expect(responses.first["result"]["content"].first["text"]).to include("OrderPlaced")
      end

      it "stats shows event count" do
        event_store.publish(OrderPlaced.new, stream_name: "Order$1")
        responses = call(server, tool_call("stats"))
        expect(responses.first["result"]["content"].first["text"]).to include("Events:  1")
      end

      it "trace shows causation tree" do
        correlation_id = SecureRandom.uuid
        event = OrderPlaced.new(metadata: { correlation_id: correlation_id })
        event_store.publish(event, stream_name: "Order$1")
        event_store.link(event.event_id, stream_name: "$by_correlation_id_#{correlation_id}")
        responses = call(server, tool_call("trace", "correlation_id" => correlation_id))
        expect(responses.first["result"]["content"].first["text"]).to include("OrderPlaced")
      end

      it "unknown tool returns isError" do
        responses = call(server, tool_call("nonexistent"))
        expect(responses.first["result"]["isError"]).to be(true)
      end
    end
  end
end
