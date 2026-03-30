# frozen_string_literal: true

module RubyEventStore
  class ImmediateAsyncDispatcher < ImmediateDispatcher
    def initialize(scheduler:)
      warn <<~EOW
        DEPRECATION WARNING: `RubyEventStore::ImmediateAsyncDispatcher` is deprecated and will be removed in the next major release.
        Use `RubyEventStore::ImmediateDispatcher` instead.
      EOW
      super
    end
  end
end
