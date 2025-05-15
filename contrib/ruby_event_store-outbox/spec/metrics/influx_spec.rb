# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Outbox
    ::RSpec.describe Metrics::Influx do
      let(:influx_url) { "http://localhost:8086" }
      let(:nanoseconds_in_second) { 1_000_000_000 }

      specify "initialization with userinfo works" do
        influx_url = "http://someuser:somepass@influxdb.example:9000/db"

        influx = Metrics::Influx.new(influx_url)

        client = influx.influxdb_client
        expect(client.config.username).to eq("someuser")
        expect(client.config.password).to eq("somepass")
        expect(client.config.hosts).to eq(["influxdb.example"])
        expect(client.config.port).to eq(9000)
        expect(client.config.database).to eq("db")
        expect(client.config.async).to be(true)
        expect(client.config.time_precision).to eq("ns")
      end

      specify "#write_point_queue defaults" do
        influx = Metrics::Influx.new(influx_url)
        client = influx.influxdb_client
        allow(client).to receive(:write_point)

        influx.write_point_queue(format: "sidekiq5", split_key: "somekey")

        expect(client).to have_received(:write_point).with(
          "ruby_event_store.outbox.queue",
          include({ values: { enqueued: 0, failed: 0, remaining: 0 } })
        )
      end

      specify "#write_point_queue" do
        influx = Metrics::Influx.new(influx_url)
        client = influx.influxdb_client
        allow(client).to receive(:write_point)

        influx.write_point_queue(format: "sidekiq5", split_key: "somekey", enqueued: 4, failed: 3, remaining: 5)

        expect(client).to have_received(:write_point).with(
          "ruby_event_store.outbox.queue",
          include(
            { values: { enqueued: 4, failed: 3, remaining: 5 }, tags: { format: "sidekiq5", split_key: "somekey" } }
          )
        )
      end

      specify "#write_operation_result" do
        influx = Metrics::Influx.new(influx_url)
        client = influx.influxdb_client
        allow(client).to receive(:write_point)

        influx.write_operation_result("obtain", "deadlocked")

        expect(client).to have_received(:write_point).with(
          "ruby_event_store.outbox.lock",
          include({ values: { value: 1 }, tags: { operation: "obtain", result: "deadlocked" } })
        )
      end

      specify "automatic timestamp assignment" do
        influx = Metrics::Influx.new(influx_url)
        client = influx.influxdb_client
        allow(client).to receive(:write_point)

        influx.write_point_queue(format: "sidekiq5", split_key: "somekey")

        expect(client).to have_received(:write_point).with(
          "ruby_event_store.outbox.queue",
          include({ timestamp: be_within(nanoseconds_in_second).of(Time.now.to_f * nanoseconds_in_second) })
        )
      end
    end
  end
end
