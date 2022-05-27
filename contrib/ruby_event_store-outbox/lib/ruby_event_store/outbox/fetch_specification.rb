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

      BIG_VALUE = 0b111111100100010000010010110010101011011101110101001100100110000

      def hash
        [self.class, message_format, split_key].hash ^ BIG_VALUE
      end

      alias_method :eql?, :==
    end
  end
end
