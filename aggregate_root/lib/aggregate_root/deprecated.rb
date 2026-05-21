# frozen_string_literal: true

module AggregateRoot
  RubyEventStore::Deprecations.register(
    :with_default_apply_strategy,
    "Please replace include AggregateRoot.with_default_apply_strategy with include AggregateRoot"
  )
  RubyEventStore::Deprecations.deprecate_class_method(AggregateRoot, :with_default_apply_strategy, key: :with_default_apply_strategy)

  RubyEventStore::Deprecations.register(
    :with_strategy,
    "Please replace include AggregateRoot.with_strategy(...) with include AggregateRoot.with(strategy: ...)"
  )
  RubyEventStore::Deprecations.deprecate_class_method(AggregateRoot, :with_strategy, key: :with_strategy)

  RubyEventStore::Deprecations.register(
    :aggregate_root_configure,
    "`AggregateRoot.configure` and `AggregateRoot::Configuration` are deprecated and will be removed in the next major release.\n" \
    "Use `AggregateRoot::Repository.new(event_store)` with explicit event store injection instead."
  )
  RubyEventStore::Deprecations.deprecate_class_method(AggregateRoot, :configure, key: :aggregate_root_configure)

  RubyEventStore::Deprecations.register(
    :repository_default_event_store,
    "Calling `AggregateRoot::Repository.new` without an event store argument relies on `AggregateRoot::Configuration` which is deprecated and will be removed in the next major release.\n" \
    "Use `AggregateRoot::Repository.new(event_store)` with explicit event store injection instead."
  )
  RubyEventStore::Deprecations.deprecate(Repository, :default_event_store, key: :repository_default_event_store)
end
