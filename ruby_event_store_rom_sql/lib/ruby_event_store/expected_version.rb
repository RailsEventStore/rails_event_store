module RubyEventStore
  class ExpectedVersion
    POSITION_DEFAULT = -1.freeze
    NOT_RESOLVED = Object.new.freeze

    def self.any
      new(:any)
    end

    attr_reader :expected

    def initialize(expected)
      @expected = expected

      # validate
      invalid_version! unless [Integer, :any, :none, :auto].any? { |i| i === expected }
    end

    def any?
      @expected == :any
    end

    def check!(stream_name)
      invalid_version! unless allowed?(stream_name)
    end

    def allowed?(stream_name)
      @expected.equal?(:any) || !stream_name.eql?(GLOBAL_STREAM)
    end

    def resolve_for(stream_name, &resolver)
      check!(stream_name)
      
      case @expected
      when Integer
        @expected
      when :any
        nil
      when :none
        POSITION_DEFAULT
      when :auto
        resolver && resolver.call(stream_name) || POSITION_DEFAULT
      else
        invalid_version!
      end
    end

  protected

    def invalid_version!
      raise InvalidExpectedVersion
    end
  end
end
