require 'spec_helper'

module RubyEventStore
  module Outbox
    RSpec.describe Metrics do
      specify do
        adapter = Metrics.from_url(nil)

        expect(adapter).to be_a(Metrics::Null)
      end

      specify do
        adapter = Metrics.from_url("http://influxdb.service.consul:8086")

        expect(adapter).to be_a(Metrics::Influx)
        expect(adapter.influxdb_client.config.hosts).to eq(["influxdb.service.consul"])
      end
    end
  end
end
