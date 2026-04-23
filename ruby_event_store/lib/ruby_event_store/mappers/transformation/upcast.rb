# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class Upcast
        class RecordUpcaster
          def initialize(upcast_map)
            @upcast_map = upcast_map
          end

          def call(record)
            identity = lambda { |r| r }
            new_record = @upcast_map.fetch(record.event_type, identity)[record]
            new_record == record ? record : call(new_record)
          end
        end

        def initialize(upcast_map)
          @record_upcaster = RecordUpcaster.new(upcast_map)
        end

        def dump(record)
          record
        end

        def load(record)
          @record_upcaster.call(record)
        end
      end
    end
  end
end
