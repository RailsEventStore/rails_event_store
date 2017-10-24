module AggregateRoot
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    def initialize
      self.strict_apply = true
    end
    attr_accessor :default_event_store
    attr_accessor :strict_apply
  end
end
