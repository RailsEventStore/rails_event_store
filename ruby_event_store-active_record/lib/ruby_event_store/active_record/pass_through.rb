# frozen_string_literal: true

require "active_record"

module RubyEventStore
  module ActiveRecord
    class PassThrough < ::ActiveRecord::Type::Value
      def serialize(value)
        value
      end

      def deserialize(value)
        value
      end
    end
  end
end
