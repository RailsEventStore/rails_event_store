# frozen_string_literal: true

require "active_record"

module RubyEventStore
  module ActiveRecord
    class PassThrough < ::ActiveModel::Type::Value
      include ::ActiveModel::Type::Helpers::Mutable

      def serialize(value)
        value
      end

      def deserialize(value)
        value
      end

      def type
        :pass_through
      end
    end
  end
end

::ActiveRecord::Type.register(:pass_through, ::RubyEventStore::ActiveRecord::PassThrough)
