# frozen_string_literal: true

module RubyEventStore
  module Deprecations
    @suppressions = []
    @warnings = {}

    class << self
      def register(key, message)
        @warnings[key] = message
      end

      def suppress(key)
        @suppressions << key
      end

      def warn(key)
        return if @suppressions.include?(key)
        Kernel.warn("[DEPRECATION] #{@warnings.fetch(key)}")
      end

      def reset!
        @suppressions = []
      end
    end
  end
end
