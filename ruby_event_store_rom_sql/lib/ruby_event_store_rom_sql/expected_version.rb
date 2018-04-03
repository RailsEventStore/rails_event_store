module RubyEventStoreRomSql
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
      case expected
      when Integer, :any, :none, :auto
      else raise RubyEventStore::InvalidExpectedVersion
      end
    end

    def any?
      @expected == :any
    end

    def check!(stream_name)
      invalid_version! unless allowed?(stream_name)
    end

    def allowed?(stream_name)
      @expected.equal?(:any) || !stream_name.eql?(RubyEventStore::GLOBAL_STREAM)
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
      raise RubyEventStore::InvalidExpectedVersion
    end
  end
end