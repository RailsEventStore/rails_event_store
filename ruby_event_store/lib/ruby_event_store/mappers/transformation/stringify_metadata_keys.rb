# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
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
            metadata: TransformKeys.stringify(item.metadata),
          )
        end
      end
    end
  end
end
