module RubyEventStore
  module TransformKeys
    private
    def stringify_keys(data)
      transform_keys(data) {|k| k.to_s}
    end
    def symbolize_keys(data)
      transform_keys(data) {|k| k.to_sym}
    end

    def transform_keys(data, &block)
      data.each_with_object({}) do |(k, v), h|
        h[yield(k)] = case v
          when Hash
            transform_keys(v, &block)
          when Array
            v.map{|i| Hash === i ? transform_keys(i, &block) : i}
          else
            v
        end
      end
    end
  end
end
