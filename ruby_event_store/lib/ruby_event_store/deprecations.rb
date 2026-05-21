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

      def deprecate(klass, method_name, key:)
        warn_key = key
        is_private = klass.private_method_defined?(method_name)
        this = self
        wrapper = Module.new do
          define_method(method_name) do |*args, **kwargs, &block|
            this.warn(warn_key)
            super(*args, **kwargs, &block)
          end
          private(method_name) if is_private
        end
        klass.prepend(wrapper)
      end

      def deprecate_class_method(klass, method_name, key:)
        warn_key = key
        this = self
        wrapper = Module.new do
          define_method(method_name) do |*args, **kwargs, &block|
            this.warn(warn_key)
            super(*args, **kwargs, &block)
          end
        end
        klass.singleton_class.prepend(wrapper)
      end

      def reset!
        @suppressions = []
        @emitted      = []
      end
    end
  end
end
