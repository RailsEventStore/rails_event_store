module RubyEventStore
  class Configuration
    def initialize
      load_defaults(VERSION)
    end

    attr_reader :loaded_defaults
    attr_accessor :test

    def load_defaults(version)
      self.test = "2.17.0" <= version ? "new_value" : "current_value"
      @loaded_defaults = version
      self
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
