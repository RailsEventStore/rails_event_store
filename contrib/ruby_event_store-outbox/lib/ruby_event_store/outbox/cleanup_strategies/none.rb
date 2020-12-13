module RubyEventStore
  module Outbox
    module CleanupStrategies
      class None
        def initialize(_repository)
        end

        def call(_fetch_specification)
        end
      end
    end
  end
end
