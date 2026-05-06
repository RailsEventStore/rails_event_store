# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/mcp"

module RubyEventStore
  ::RSpec.describe MCP do
    let(:event_store) { RubyEventStore::Client.new }

    describe ".server" do
      subject(:server) { MCP.server(event_store) }

      it "returns a Server instance" do
        expect(server).to be_a(MCP::Server)
      end

      it "configures the given event store" do
        expect(server.event_store).to eq(event_store)
      end

      it "registers exactly the 8 standard tools" do
        expect(server.tools.map(&:name)).to contain_exactly(
          "stream_show", "stream_events", "event_show",
          "event_streams", "search", "stats", "trace", "aggregate_history"
        )
      end

      it "includes stream_show tool" do
        expect(server.tools.map(&:name)).to include("stream_show")
      end

      it "includes stream_events tool" do
        expect(server.tools.map(&:name)).to include("stream_events")
      end

      it "includes event_show tool" do
        expect(server.tools.map(&:name)).to include("event_show")
      end

      it "includes event_streams tool" do
        expect(server.tools.map(&:name)).to include("event_streams")
      end

      it "includes search tool" do
        expect(server.tools.map(&:name)).to include("search")
      end

      it "includes stats tool" do
        expect(server.tools.map(&:name)).to include("stats")
      end

      it "includes trace tool" do
        expect(server.tools.map(&:name)).to include("trace")
      end
    end
  end
end
