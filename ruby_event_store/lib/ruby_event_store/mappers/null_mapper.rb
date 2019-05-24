require 'forwardable'

module RubyEventStore
  module Mappers
    class NullMapper
      extend Forwardable
      class NULL
        def self.dump(event)
          event
        end

        def self.load(record)
          record
        end
      end
      private_constant :NULL


      def initialize
        @mapper = Default.new(serializer: NULL)
      end

      def_delegators :@mapper, :event_to_serialized_record, :serialized_record_to_event
    end
  end
end
