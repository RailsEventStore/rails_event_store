# frozen_string_literal: true

module RubyEventStore
  class Dispatcher < SyncScheduler
    Deprecations.register(
      :dispatcher_renamed,
      "`RubyEventStore::Dispatcher` is deprecated and will be removed in the next major release.\n" \
      "Use `RubyEventStore::SyncScheduler` instead."
    )

    def initialize
      Deprecations.warn(:dispatcher_renamed)
    end
  end
end
