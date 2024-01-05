# frozen_string_literal: true

module RubyEventStore
  module Outbox
    module CleanupStrategies
      def self.build(configuration, repository)
        case configuration.cleanup
        when :none
          None.new
        else
          CleanOldEnqueued.new(
            repository,
            ActiveSupport::Duration.parse(configuration.cleanup),
            configuration.cleanup_limit
          )
        end
      end
    end
  end
end
