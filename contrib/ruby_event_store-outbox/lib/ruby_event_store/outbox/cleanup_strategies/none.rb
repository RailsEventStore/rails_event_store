module RubyEventStore
  module Outbox
    module CleanupStrategies
      class None
        def initialize
        end

        def call(_fetch_specification)
        end
      end
    end
  end
end
