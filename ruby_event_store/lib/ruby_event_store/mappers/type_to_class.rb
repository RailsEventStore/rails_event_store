module RubyEventStore
  module Mappers
    class TypeToClass
      def call(event_type)
        Object.const_get(event_type)
      end
    end
  end
end
