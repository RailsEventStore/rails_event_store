# frozen_string_literal: true

module RubyEventStore
  module Outbox
    class FetchSpecification
      def initialize(message_format, split_key)
        @message_format = message_format
        @split_key = split_key
        freeze
      end

      attr_reader :message_format, :split_key

      def ==(other)
        other.instance_of?(self.class) && other.message_format.eql?(message_format) && other.split_key.eql?(split_key)
      end

      def hash
        [message_format, split_key].hash ^ self.class.hash
      end

      alias_method :eql?, :==
    end
  end
end
