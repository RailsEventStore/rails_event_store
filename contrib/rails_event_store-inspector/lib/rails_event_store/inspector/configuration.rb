# frozen_string_literal: true

module RailsEventStore
  module Inspector
    class Configuration
      attr_accessor :enabled

      attr_accessor :scope

      def initialize
        @enabled = ->(_env) { defined?(::Rails) && ::Rails.respond_to?(:env) && ::Rails.env.development? }
        @scope = nil
      end
    end
  end
end
