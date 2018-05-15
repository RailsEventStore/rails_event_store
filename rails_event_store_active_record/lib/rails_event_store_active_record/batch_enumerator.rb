module RailsEventStoreActiveRecord
  class BatchEnumerator
    def initialize(batch_size, total_limit, reader)
      @batch_size  = batch_size
      @total_limit = total_limit
      @reader      = reader
    end

    def each
      Enumerator.new do |y|
        (0..Float::INFINITY).step(batch_size) do |batch_offset|
          batch_limit = [batch_size, total_limit - batch_offset, total_limit].min
          result      = reader.call(batch_offset, batch_limit)

          break if result.empty?
          y << result
          break if result.size < batch_size
        end
      end
    end

    private

    attr_accessor :batch_size, :total_limit, :reader
  end
end
