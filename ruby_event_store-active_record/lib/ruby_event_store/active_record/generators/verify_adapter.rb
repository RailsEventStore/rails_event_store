# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    UnsupportedAdapter = Class.new(StandardError)

    class VerifyAdapter
      SUPPORTED_ADAPTERS = %w[mysql2 postgresql sqlite].freeze

      def call(adapter)
        raise UnsupportedAdapter, "Unsupported adapter" unless supported?(adapter)
      end

      private

      private_constant :SUPPORTED_ADAPTERS

      def supported?(adapter)
        SUPPORTED_ADAPTERS.include?(adapter.downcase)
      end
    end
  end
end
