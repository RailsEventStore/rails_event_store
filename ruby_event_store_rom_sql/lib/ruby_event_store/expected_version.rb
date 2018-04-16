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

    def resolve_for(stream, &resolver)
      invalid_version! if stream.global? && !any?

      case version
      when Integer
        version
      when :any
        nil
      when :none
        POSITION_DEFAULT
      when :auto
        resolver && resolver.call(stream) || POSITION_DEFAULT
      else
        invalid_version!
      end
    end

    private

    def invalid_version!
      raise InvalidExpectedVersion
    end
  end
end
