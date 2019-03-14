module RubyEventStore
  module Mappers
    class TypeToClass
      def call(event_type)
        ->(args) { Object.const_get(event_type).new(args) }
      end
    end
  end
end
