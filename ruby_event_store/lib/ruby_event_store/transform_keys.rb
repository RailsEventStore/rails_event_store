# frozen_string_literal: true

module RubyEventStore
  class TransformKeys
    class << self
      def stringify(data)
        deep_transform(data, &:to_s)
      end

      def symbolize(data)
        deep_transform(data, &:to_sym)
      end

      private

      def deep_transform(data, &block)
        case data
        when Hash
          data.each_with_object({}) { |(key, value), hash| hash[yield(key)] = deep_transform(value, &block) }
        when Array
          data.map { |i| deep_transform(i, &block) }
        else
          data
        end
      end
    end
  end
end
