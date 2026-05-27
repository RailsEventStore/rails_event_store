# frozen_string_literal: true

module AggregateRoot
  RubyEventStore::Deprecations.register(
    :with_default_apply_strategy,
    "Please replace include AggregateRoot.with_default_apply_strategy with include AggregateRoot",
  )
  RubyEventStore::Deprecations.deprecate_class_method(
    AggregateRoot,
    :with_default_apply_strategy,
    key: :with_default_apply_strategy,
  )

  RubyEventStore::Deprecations.register(
    :with_strategy,
    "Please replace include AggregateRoot.with_strategy(...) with include AggregateRoot.with(strategy: ...)",
  )
  RubyEventStore::Deprecations.deprecate_class_method(AggregateRoot, :with_strategy, key: :with_strategy)

end
