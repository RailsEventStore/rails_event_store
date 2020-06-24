module RubyEventStore
  module Outbox
    module Metrics
      class Null
        def write_point_queue(deadlocked:, enqueued: 0, failed: 0)
        end
      end
    end
  end
end
