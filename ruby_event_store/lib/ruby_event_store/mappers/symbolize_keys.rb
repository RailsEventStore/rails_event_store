module RubyEventStore
  module Mappers
    class SymbolizeKeys
      def initialize(symbolize_data: true, symbolize_metadata: true)
        @symbolize_data = symbolize_data
        @symbolize_metadata = symbolize_metadata
      end

      def dump(item)
        item
      end

      def load(item)
        item.dup.tap do |result|
          result.merge!(data: TransformKeys.symbolize(item.fetch(:data))) if @symbolize_data
          result.merge!(metadata: TransformKeys.symbolize(item.fetch(:metadata))) if @symbolize_metadata
        end
      end
    end
  end
end
