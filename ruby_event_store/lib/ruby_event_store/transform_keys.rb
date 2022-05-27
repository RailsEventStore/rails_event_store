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
        data.each_with_object({}) do |(k, v), h|
          h[yield(k)] =
            case v
            when Hash
              deep_transform(v, &block)
            when Array
              v.map { |i| Hash === i ? deep_transform(i, &block) : i }
            else
              v
            end
        end
      end
    end
  end
end
