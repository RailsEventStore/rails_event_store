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

    def hash
      name.hash ^ self.class.hash
    end

    def ==(other_stream)
      other_stream.instance_of?(self.class) && other_stream.name.eql?(name)
    end

    alias_method :eql?, :==
  end
end
