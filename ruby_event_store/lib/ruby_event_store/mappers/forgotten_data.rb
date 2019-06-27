# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class ForgottenData
      FORGOTTEN_DATA = 'FORGOTTEN_DATA'.freeze

      def initialize(string = FORGOTTEN_DATA)
        @string = string
      end

      def to_s
        @string
      end

      def ==(other)
        @string == other
      end
      alias_method :eql?, :==

      def method_missing(*)
        self
      end

      def respond_to_missing?(*)
        true
      end
    end
  end
end
