module RubyEventStore
  module Mappers
    class StringifyMetadataKeys
      def dump(item)
        stringify(item)
      end

      def load(item)
        stringify(item)
      end

      private
      def stringify(item)
        item.merge(
          metadata: TransformKeys.stringify(item.fetch(:metadata)),
        )
      end
    end
  end
end
