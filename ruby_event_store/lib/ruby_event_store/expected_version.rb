# frozen_string_literal: true

module RubyEventStore
  class ExpectedVersion
    POSITION_DEFAULT = -1.freeze
    NOT_RESOLVED = Object.new.freeze

    def self.any
      new(:any)
    end

    def self.none
      new(:none)
    end

    def self.auto
      new(:auto)
    end

    attr_reader :version

    def initialize(version)
      @version = version
      invalid_version! unless [Integer, :any, :none, :auto].any? {|i| i === version}
    end

    def any?
      version.equal?(:any)
    end

    def auto?
      version.equal?(:auto)
    end

    def none?
      version.equal?(:none)
    end

    def resolve_for(stream, resolver = Proc.new {})
      invalid_version! if stream.global? && !any?

      case version
      when Integer
        version
      when :none
        POSITION_DEFAULT
      when :auto
        resolver[stream] || POSITION_DEFAULT
      end
    end

    BIG_VALUE = 0b110111100100000010010010110011101011000101010101001100100110011
    private_constant :BIG_VALUE

    def hash
      [
        self.class,
        version
      ].hash ^ BIG_VALUE
    end

    def ==(other_expected_version)
      other_expected_version.instance_of?(self.class) &&
        other_expected_version.version.equal?(version)
    end

    alias_method :eql?, :==

    private

    def invalid_version!
      raise InvalidExpectedVersion
    end
  end
end
