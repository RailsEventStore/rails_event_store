# frozen_string_literal: true

module RubyEventStore
  module Outbox
    module CleanupStrategies
      class CleanOldEnqueued
        def initialize(repository, duration, limit)
          @repository = repository
          @duration = duration
          @limit = limit
        end

        def call(fetch_specification)
          repository.delete_enqueued_older_than(fetch_specification, duration, limit)
        end

        private

        attr_reader :repository, :duration, :limit
      end
    end
  end
end
