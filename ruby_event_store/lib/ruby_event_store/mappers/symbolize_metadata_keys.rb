module RubyEventStore
  module Mappers
    class SymbolizeMetadataKeys
      def dump(item)
        item
      end

      def load(item)
        item.merge(
          metadata: TransformKeys.symbolize(item.fetch(:metadata)),
        )
      end
    end
  end
end
