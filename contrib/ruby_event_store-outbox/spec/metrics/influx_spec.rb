require 'spec_helper'

module RubyEventStore
  module Outbox
    RSpec.describe Metrics::Influx do
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
        expect(client.config.async).to eq(true)
        expect(client.config.time_precision).to eq('ns')
      end

      # This is needed for cases when password contains characters which are allowed as influxdb password, but not allowed as password in URI standard -- in params they can be percent-encoded
      specify "initialization with username & password as params works" do
        influx_url = "http://influxdb.example:9000/db?username=someuser&password=some%24weird%25pass"

        influx = Metrics::Influx.new(influx_url)

        client = influx.influxdb_client
        expect(client.config.username).to eq("someuser")
        expect(client.config.password).to eq("some$weird%pass")
        expect(client.config.hosts).to eq(["influxdb.example"])
        expect(client.config.port).to eq(9000)
        expect(client.config.database).to eq("db")
      end

      specify "#write_point_queue defaults" do
        influx = Metrics::Influx.new(influx_url)
        client = influx.influxdb_client
        allow(client).to receive(:write_point)

        influx.write_point_queue(operation: "process", status: "ok")

        expect(client).to have_received(:write_point).with("ruby_event_store.outbox.queue", {
          timestamp: be_present,
          values: {
            enqueued: 0,
            failed: 0,
            remaining: 0,
          },
          tags: {
            operation: "process",
            status: "ok",
            format: nil,
            split_key: nil,
          }
        })
      end

      specify "#write_point_queue" do
        influx = Metrics::Influx.new(influx_url)
        client = influx.influxdb_client
        allow(client).to receive(:write_point)

        influx.write_point_queue(operation: "process", status: "ok", enqueued: 4, failed: 3, remaining: 5)

        expect(client).to have_received(:write_point).with("ruby_event_store.outbox.queue", {
          timestamp: be_present,
          values: {
            enqueued: 4,
            failed: 3,
            remaining: 5,
          },
          tags: {
            operation: "process",
            status: "ok",
            format: nil,
            split_key: nil,
          }
        })
      end

      specify "automatic timestamp assignment" do
        influx = Metrics::Influx.new(influx_url)
        client = influx.influxdb_client
        allow(client).to receive(:write_point)

        influx.write_point_queue(operation: "process", status: "ok")

        expect(client).to have_received(:write_point).with("ruby_event_store.outbox.queue", include({
          timestamp: be_within(nanoseconds_in_second).of(Time.now.to_f * nanoseconds_in_second)
        }))
      end
    end
  end
end
