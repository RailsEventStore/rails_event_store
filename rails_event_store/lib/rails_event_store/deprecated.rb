# frozen_string_literal: true

module RailsEventStore
  RubyEventStore::Deprecations.register(
    :after_commit_async_dispatcher_renamed,
    "`RailsEventStore::AfterCommitAsyncDispatcher` is deprecated and will be removed in the next major release.\n" \
    "Use `RailsEventStore::AfterCommitDispatcher` instead."
  )
  RubyEventStore::Deprecations.deprecate(AfterCommitAsyncDispatcher, :initialize, key: :after_commit_async_dispatcher_renamed)
end
