# frozen_string_literal: true

require_relative "inspector/version"
require_relative "inspector/configuration"
require_relative "inspector/buffer"
require_relative "inspector/frames"

module RailsEventStore
  module Inspector
    ACTIVE = :res_inspector_active
    SCOPE = :res_inspector_scope

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def active?
        Thread.current[ACTIVE] == true
      end

      def scope
        Thread.current[SCOPE]
      end

      def buffer
        @buffer ||= Buffer.new
      end
    end
  end
end
