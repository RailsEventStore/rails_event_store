module RailsEventStoreActiveRecord
  class BatchEnumerator
    def initialize(spec)
      @batch_size  = spec.batch_size
      @total_limit = spec.limit? ? spec.count : Float::INFINITY
    end

    def each(&block)
      Enumerator.new do |y|
        0.upto(Float::INFINITY) do |index|
          result = block.call(
            batch_offset = batch_size * index,
            [batch_size, total_limit - batch_offset, total_limit].min
          )
          break if result.empty?

          y << result

          break if result.size < batch_size
        end
      end
    end
    
    attr_accessor :batch_size, :total_limit
  end
end
