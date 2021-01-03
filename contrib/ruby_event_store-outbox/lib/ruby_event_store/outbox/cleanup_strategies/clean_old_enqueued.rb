module RubyEventStore
  module Outbox
    module CleanupStrategies
      class CleanOldEnqueued
        def initialize(repository, duration)
          @repository = repository
          @duration = duration
        end

        def call(fetch_specification)
          repository.delete_enqueued_older_than(fetch_specification, duration)
        end

        private
        attr_reader :repository, :duration
      end
    end
  end
end
