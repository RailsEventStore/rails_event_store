# frozen_string_literal: true

module RailsEventStore
  class AfterCommitAsyncDispatcher < AfterCommitDispatcher
    RubyEventStore::Deprecations.register(
      :after_commit_async_dispatcher_renamed,
      "`RailsEventStore::AfterCommitAsyncDispatcher` is deprecated and will be removed in the next major release.\n" \
      "Use `RailsEventStore::AfterCommitDispatcher` instead."
    )

    def initialize(scheduler:)
      RubyEventStore::Deprecations.warn(:after_commit_async_dispatcher_renamed)
      super
    end
  end
end
