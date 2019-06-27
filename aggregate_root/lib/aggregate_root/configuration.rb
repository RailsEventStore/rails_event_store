# frozen_string_literal: true

module AggregateRoot
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :default_event_store
  end
end
