module RubyEventStore
  module Mappers
    class Pipeline
      def initialize(transformations)
        @transformations = transformations
      end

      def dump(domain_event)
        transformations.reduce(domain_event) do |item, transform|
          transform.dump(item)
        end
      end

      def load(record)
        transformations.reverse.reduce(record) do |item, transform|
          transform.load(item)
        end
      end

      private
      attr_reader :transformations
    end
  end
end
