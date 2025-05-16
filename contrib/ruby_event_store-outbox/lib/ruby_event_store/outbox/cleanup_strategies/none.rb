# frozen_string_literal: true

module RubyEventStore
  module Outbox
    module CleanupStrategies
      class None
        def initialize
        end

        def call(_fetch_specification)
          :ok
        end
      end
    end
  end
end
