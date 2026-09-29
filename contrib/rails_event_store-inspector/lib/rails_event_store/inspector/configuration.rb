# frozen_string_literal: true

module RailsEventStore
  module Inspector
    class Configuration
      DEVELOPMENT_ONLY = ->(_env) { defined?(::Rails) && ::Rails.respond_to?(:env) && ::Rails.env.development? }

      attr_accessor :enabled

      attr_accessor :scope

      attr_writer :install

      def initialize
        @enabled = DEVELOPMENT_ONLY
        @scope = nil
        @install = nil
      end

      def install?
        return @install.call if @install
        gated_by_default? ? DEVELOPMENT_ONLY.call(nil) : true
      end

      private

      def gated_by_default?
        @enabled.equal?(DEVELOPMENT_ONLY)
      end
    end
  end
end
