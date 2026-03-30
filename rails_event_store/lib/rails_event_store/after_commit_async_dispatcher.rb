# frozen_string_literal: true

module RailsEventStore
  class AfterCommitAsyncDispatcher < AfterCommitDispatcher
    def initialize(scheduler:)
      warn <<~EOW
        DEPRECATION WARNING: `RailsEventStore::AfterCommitAsyncDispatcher` is deprecated and will be removed in the next major release.
        Use `RailsEventStore::AfterCommitDispatcher` instead.
      EOW
      super
    end
  end
end
