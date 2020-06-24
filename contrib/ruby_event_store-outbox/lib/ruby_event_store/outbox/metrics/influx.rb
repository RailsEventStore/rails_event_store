require 'influxdb'

module RubyEventStore
  module Outbox
    module Metrics
      class Influx
        def initialize(url)
          @influxdb_client = InfluxDB::Client.new(url: url, async: true, time_precision: 'ns')
        end

        def write_point_queue(deadlocked:, enqueued: 0, failed: 0)
          write_point("ruby_event_store.outbox.queue", {
            values: {
              deadlocked: deadlocked,
              enqueued: enqueued,
              failed: failed,
            }
          })
        end

        def write_point(series, data)
          data[:timestamp] ||= Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond).to_i
          @influxdb_client.write_point(series, data)
        end

        private
        attr_reader :influxdb_client
      end
    end
  end
end
