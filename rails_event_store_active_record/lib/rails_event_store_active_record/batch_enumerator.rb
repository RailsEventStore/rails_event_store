# frozen_string_literal: true

module RailsEventStoreActiveRecord
  class BatchEnumerator
    def initialize(batch_size, total_limit, reader, builder)
      @batch_size = batch_size
      @total_limit = total_limit
      @reader = reader
      @builder = builder
    end

    def each
      return to_enum unless block_given?
      offset_id = nil

      0.step(total_limit - 1, batch_size) do |batch_offset|
        batch_limit  = [batch_size, total_limit - batch_offset].min
        records  = reader.call(offset_id, batch_limit)

        break if records.empty?
        offset_id = records.last.id
        yield records.map(&builder)
      end
    end

    def first
      each.first
    end

    def to_a
      each.to_a
    end

    private

    attr_reader :batch_size, :total_limit, :reader, :builder
  end
end

