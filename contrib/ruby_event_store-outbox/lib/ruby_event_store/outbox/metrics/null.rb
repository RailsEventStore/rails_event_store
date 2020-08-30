module RubyEventStore
  module Outbox
    module Metrics
      class Null
        def write_operation_result(operation, result)
        end

        def write_point_queue(**kwargs)
        end
      end
    end
  end
end
