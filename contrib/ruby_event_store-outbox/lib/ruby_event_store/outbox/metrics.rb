require "ruby_event_store/outbox/metrics/null"
require "ruby_event_store/outbox/metrics/influx"

module RubyEventStore
  module Outbox
    module Metrics
      def self.from_url(metrics_url)
        if metrics_url.nil?
          Null.new
        else
          Influx.new(metrics_url)
        end
      end
    end
  end
end
