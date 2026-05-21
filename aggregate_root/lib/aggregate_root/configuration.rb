# frozen_string_literal: true

module AggregateRoot
  RubyEventStore::Deprecations.register(
    :aggregate_root_configure,
    "`AggregateRoot.configure` and `AggregateRoot::Configuration` are deprecated and will be removed in the next major release.\n" \
    "Use `AggregateRoot::Repository.new(event_store)` with explicit event store injection instead."
  )

  class << self
    attr_accessor :configuration
  end

  def self.configure
    RubyEventStore::Deprecations.warn(:aggregate_root_configure)
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :default_event_store
  end
end
