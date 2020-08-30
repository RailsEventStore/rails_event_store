module RubyEventStore
  module Outbox
    class FetchSpecification
      def initialize(message_format, split_key)
        @message_format = message_format
        @split_key = split_key
        freeze
      end

      attr_reader :message_format, :split_key
    end
  end
end
