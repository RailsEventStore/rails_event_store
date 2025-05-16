# frozen_string_literal: true

require "influxdb"

module RubyEventStore
  module Outbox
    module Metrics
      class Test
        def initialize
          @operation_results = []
          @queue_stats = []
        end

        def write_operation_result(operation, result)
          @operation_results << { operation: operation, result: result }
        end

        def write_point_queue(enqueued: 0, failed: 0, remaining: 0, format: nil, split_key: nil)
          @queue_stats << {
            enqueued: enqueued,
            failed: failed,
            remaining: remaining,
            format: format,
            split_key: split_key,
          }
        end

        attr_reader :operation_results, :queue_stats
      end
    end
  end
end
