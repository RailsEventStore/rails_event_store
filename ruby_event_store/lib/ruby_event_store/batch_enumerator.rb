module RubyEventStore
  class BatchEnumerator
    def initialize(batch_size, total_limit, reader)
      @batch_size  = batch_size
      @total_limit = total_limit
      @reader      = reader
    end

    def each
      enum = Enumerator.new do |y|
        (0...total_limit).step(batch_size) do |batch_offset|
          batch_offset = Integer(batch_offset)
          batch_limit  = [batch_size, total_limit - batch_offset].min
          result       = reader.call(batch_offset, batch_limit)

          break if result.empty?
          y << result
        end
      end
      enum.each { |batch| yield batch } if block_given?
      enum
    end

    private

    attr_accessor :batch_size, :total_limit, :reader
  end
end
