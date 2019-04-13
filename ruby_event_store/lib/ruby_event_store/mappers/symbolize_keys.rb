module RubyEventStore
  module Mappers
    class SymbolizeKeys
      def dump(item)
        item
      end

      def load(item)
        item.merge(
          data: TransformKeys.symbolize(item.fetch(:data)),
          metadata: TransformKeys.symbolize(item.fetch(:metadata)),
        )
      end
    end
  end
end
