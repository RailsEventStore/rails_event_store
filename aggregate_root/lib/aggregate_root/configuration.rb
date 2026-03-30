# frozen_string_literal: true

module AggregateRoot
  class << self
    attr_accessor :configuration
  end

  def self.configure
    warn <<~EOW
      DEPRECATION WARNING: `AggregateRoot.configure` and `AggregateRoot::Configuration` are deprecated and will be removed in the next major release.
      Use `AggregateRoot::Repository.new(event_store)` with explicit event store injection instead.
    EOW
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :default_event_store
  end
end
