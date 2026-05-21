# frozen_string_literal: true

module RubyEventStore
  module Deprecations
    @suppressions = []
    @warnings     = {}
    @emitted      = []

    class << self
      def register(key, message)
        @warnings[key] = message
      end

      def suppress(key)
        @suppressions << key
      end

      def warn(key, message: nil)
        return if @suppressions.include?(key)
        return if @emitted.include?(key)
        @emitted << key
        Kernel.warn("[DEPRECATION] #{message || @warnings.fetch(key)}")
      end

      def reset!
        @suppressions = []
        @emitted      = []
      end
    end
  end
end
