# frozen_string_literal: true

require_relative "spec_helper"
require "ruby_event_store/cli/commands"

module RubyEventStore
  module CLI
    class OrderPlaced < RubyEventStore::Event; end

    RSpec.describe "CLI integration" do
      let(:event_store) { RubyEventStore::Client.new }
      before { stub_event_store(event_store) }

      def cli(argv)
        stub_const("ARGV", argv)
        Dry::CLI.new(Commands).call
      end

      it "stream events" do
        event_store.publish(OrderPlaced.new, stream_name: "orders")
        expect { cli(["stream", "events", "orders"]) }.to output(/OrderPlaced/).to_stdout
      end

      it "stream show" do
        event_store.publish(OrderPlaced.new, stream_name: "orders")
        expect { cli(["stream", "show", "orders"]) }.to output(/Events:\s+1/).to_stdout
      end

      it "event show" do
        event = OrderPlaced.new
        event_store.publish(event, stream_name: "orders")
        expect { cli(["event", "show", event.event_id]) }.to output(/OrderPlaced/).to_stdout
      end

      it "event streams" do
        event = OrderPlaced.new
        event_store.publish(event, stream_name: "orders")
        expect { cli(["event", "streams", event.event_id]) }.to output(/orders/).to_stdout
      end

      it "trace" do
        correlation_id = SecureRandom.uuid
        event = OrderPlaced.new
        event_store.with_metadata(correlation_id: correlation_id) { event_store.publish(event, stream_name: "orders") }
        event_store.link(event.event_id, stream_name: "$by_correlation_id_#{correlation_id}")
        expect { cli(["trace", correlation_id]) }.to output(/OrderPlaced/).to_stdout
      end

      it "search" do
        event_store.publish(OrderPlaced.new, stream_name: "orders")
        expect { cli(["search"]) }.to output(/OrderPlaced/).to_stdout
      end

      it "stats" do
        event_store.publish(OrderPlaced.new, stream_name: "orders")
        expect { cli(["stats"]) }.to output(/Events:\s+1/).to_stdout
      end

      it "watch" do
        allow_any_instance_of(Commands::Watch).to receive(:sleep) { raise Interrupt }
        expect { cli(["watch"]) }.to raise_error(SystemExit) { |e| expect(e.status).to eq(0) }
      end
    end
  end
end
