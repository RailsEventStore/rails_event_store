module RubyEventStore
  module Mappers
    class SymbolizeMetadataKeys
      def dump(item)
        symbolize(item)
      end

      def load(item)
        symbolize(item)
      end

      private
      def symbolize(item)
        item.merge(
          metadata: TransformKeys.symbolize(item.fetch(:metadata)),
        )
      end
    end
  end
end
