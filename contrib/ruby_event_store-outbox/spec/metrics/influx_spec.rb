require 'spec_helper'

module RubyEventStore
  module Outbox
    RSpec.describe Metrics::Influx do
      specify "userinfo works" do
        influx_url = "http://someuser:somepass@influxdb.example:9000/db"

        influx = Metrics::Influx.new(influx_url)

        client = influx.influxdb_client
        expect(client.config.username).to eq("someuser")
        expect(client.config.password).to eq("somepass")
        expect(client.config.hosts).to eq(["influxdb.example"])
        expect(client.config.port).to eq(9000)
        expect(client.config.database).to eq("db")
      end

      # This is needed for cases when password contains characters which are allowed as influxdb password, but not allowed as password in URI standard -- in params they can be percent-encoded
      specify "username & password as params works" do
        influx_url = "http://influxdb.example:9000/db?username=someuser&password=some%24weird%25pass"

        influx = Metrics::Influx.new(influx_url)

        client = influx.influxdb_client
        expect(client.config.username).to eq("someuser")
        expect(client.config.password).to eq("some$weird%pass")
        expect(client.config.hosts).to eq(["influxdb.example"])
        expect(client.config.port).to eq(9000)
        expect(client.config.database).to eq("db")
      end
    end
  end
end
