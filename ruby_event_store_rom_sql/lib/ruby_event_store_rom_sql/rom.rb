module RubyEventStoreRomSql
  module ROM
    TupleNotFound = Class.new(::ROM::TupleCountMismatchError) do
      attr_accessor :tuple_id, :relation
    end
  end
end

require_relative 'rom/mappers/serialized_record'
require_relative 'rom/relations/event_streams'
require_relative 'rom/relations/events'
require_relative 'rom/repositories/event_streams'
require_relative 'rom/repositories/events'
