module RailsEventStoreActiveRecord
  class BatchEnumerator
    def initialize(spec)
      self.spec = spec
    end

    def each(&block)
      Enumerator.new do |y|
        offset = 0
        limit = spec.limit? ? spec.count : spec.batch_size
        loop do
          batch_limit = [spec.batch_size, limit].min

          result = block.call(offset, batch_limit)

          offset += spec.batch_size
          limit -= spec.batch_size if spec.limit?
          break if result.empty?
          y << result
          break if result.size < spec.batch_size
        end
      end
    end

    private

    attr_accessor :spec
  end
end
