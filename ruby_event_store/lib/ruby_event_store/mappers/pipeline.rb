# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class Pipeline
      UNSET = Object.new.freeze

      def initialize(*transformations_, transformations: UNSET, to_domain_event: Transformation::DomainEvent.new)
        @transformations = [
          to_domain_event,
          deprecated_transformations(transformations),
          transformations_,
        ].flatten.freeze
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

      attr_reader :transformations

      private

      def deprecated_transformations(transformations)
        case transformations
        when UNSET
          []
        else
          warn <<~EOW
            Passing transformations via keyword parameter is deprecated.
            Please use positional arguments from now on.
          
            Was:
              RubyEventStore::Mappers::Pipeline.new(transformations: transformations)
          
            Is now:
              RubyEventStore::Mappers::Pipeline.new(*transformations)
          EOW
          transformations
        end
      end
    end
  end
end
