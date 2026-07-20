# frozen_string_literal: true

require "base64"

module RailsEventStore
  module Encoding
    module Base64
      class Transformation
        def dump(record)
          recode(record) { |value| ::Base64.strict_encode64(value) }
        end

        def load(record)
          recode(record) { |value| ::Base64.strict_decode64(value) }
        end

        private

        def recode(record, &coder)
          return record unless record.metadata.key?(:encryption)

          data = deep_dup(record.data)
          metadata = deep_dup(record.metadata)
          recode_encrypted(data, metadata.fetch(:encryption), &coder)
          record.with(data: data, metadata: metadata)
        end

        def recode_encrypted(data, description, &coder)
          description.each do |attribute, leaf_or_branch|
            if leaf?(leaf_or_branch)
              data[attribute] = coder.call(data[attribute]) unless data[attribute].nil?
              leaf_or_branch[:iv] = coder.call(leaf_or_branch[:iv])
            else
              recode_encrypted(data.fetch(attribute), leaf_or_branch, &coder)
            end
          end
        end

        def leaf?(value)
          value.keys.sort == %i[cipher identifier iv]
        end

        def deep_dup(hash)
          hash.each_with_object({}) { |(key, value), copy| copy[key] = value.is_a?(::Hash) ? deep_dup(value) : value }
        end
      end

      private

      def transformations
        [Transformation.new, *super]
      end
    end
  end
end
