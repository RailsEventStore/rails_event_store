require 'influxdb'

module RubyEventStore
  module Outbox
    module Metrics
      class Influx
        def initialize(url)
          uri = URI.parse(url)
          params = CGI.parse(uri.query || "")
          options = {
            url: url,
            async: true,
            time_precision: 'ns',
          }
          options[:username] = params.fetch("username").first if params.key?("username")
          options[:password] = params.fetch("password").first if params.key?("password")
          @influxdb_client = InfluxDB::Client.new(**options)
        end

        def write_point_queue(status:, enqueued: 0, failed: 0)
          write_point("ruby_event_store.outbox.queue", {
            values: {
              enqueued: enqueued,
              failed: failed,
            },
            tags: {
              status: status,
            }
          })
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
