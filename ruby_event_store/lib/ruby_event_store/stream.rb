# frozen_string_literal: true

module RubyEventStore
  class Stream
    def initialize(name)
      raise IncorrectStreamData if !name.equal?(GLOBAL_STREAM) && (name.nil? || name.empty?)
      @name = name
    end

    def global?
      name.equal?(GLOBAL_STREAM)
    end

    attr_reader :name

    BIG_VALUE = 0b111111100100000010010010110011101011000101010101001100100110011
    def hash
      [
        self.class,
        name
      ].hash ^ BIG_VALUE
    end

    def ==(other_stream)
      other_stream.instance_of?(self.class) &&
        other_stream.name.eql?(name)
    end

    alias_method :eql?, :==

    private_constant :BIG_VALUE
  end
end