# frozen_string_literal: true

module RubyEventStore
  module Outbox
    module Metrics
      def self.from_url(metrics_url)
        if metrics_url.nil?
          require_relative "metrics/null"
          Null.new
        else
          require_relative "metrics/influx"
          Influx.new(metrics_url)
        end
      end
    end
  end
end
