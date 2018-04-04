require 'date'
require 'time'

module RubyEventStore
  class Metadata
    def initialize(h = self)
      @h = {}
      h.each do |k, v|
        self[k] = (v)
      end
    end

    def [](key)
      raise ArgumentError unless Symbol === key
      @h[key]
    end

    def []=(key, val)
      raise ArgumentError unless allowed_types.any?{|klass| klass === val }
      @h[key]=val
    end

    def each(&block)
      @h.each(&block)
    end

    def to_h
      @h.dup
    end

    private

    def allowed_types
      [String, Integer, Float, Date, Time, TrueClass, FalseClass]
    end
  end
end