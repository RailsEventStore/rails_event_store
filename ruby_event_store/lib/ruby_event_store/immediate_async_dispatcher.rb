# frozen_string_literal: true

module RubyEventStore
  class ImmediateAsyncDispatcher < ImmediateDispatcher
    Deprecations.register(
      :immediate_async_dispatcher_renamed,
      "`RubyEventStore::ImmediateAsyncDispatcher` is deprecated and will be removed in the next major release.\n" \
      "Use `RubyEventStore::ImmediateDispatcher` instead."
    )

    def initialize(scheduler:)
      Deprecations.warn(:immediate_async_dispatcher_renamed)
      super
    end
  end
end
