module RubyEventStore
  module Outbox
    module Metrics
      def self.from_url(metrics_url)
        if metrics_url.nil?
          require "ruby_event_store/outbox/metrics/null"
          Null.new
        else
          require "ruby_event_store/outbox/metrics/influx"
          Influx.new(metrics_url)
        end
      end
    end
  end
end
