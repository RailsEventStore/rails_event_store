# frozen_string_literal: true

require "cgi"
require "uri"

# influxdb 0.8.x uses CGI.parse which was removed in Ruby 4.0
unless CGI.respond_to?(:parse)
  CGI.define_singleton_method(:parse) do |query|
    URI.decode_www_form(query || "").each_with_object({}) { |(k, v), h| (h[k] ||= []) << v }
  end
end

require "influxdb"

module RubyEventStore
  module Outbox
    module Metrics
      class Influx
        def initialize(url)
          options = { url: url, async: true, time_precision: "ns" }
          @influxdb_client = InfluxDB::Client.new(**options)
        end

        def write_operation_result(operation, result)
          write_point(
            "ruby_event_store.outbox.lock",
            { values: { value: 1 }, tags: { operation: operation, result: result } },
          )
        end

        def write_point_queue(enqueued: 0, failed: 0, remaining: 0, format: nil, split_key: nil)
          write_point(
            "ruby_event_store.outbox.queue",
            {
              values: {
                enqueued: enqueued,
                failed: failed,
                remaining: remaining,
              },
              tags: {
                format: format,
                split_key: split_key,
              },
            },
          )
        end

        def write_point(series, data)
          data[:timestamp] = Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)
          influxdb_client.write_point(series, data)
        end

        attr_reader :influxdb_client
      end
    end
  end
end
