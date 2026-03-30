# frozen_string_literal: true

module RubyEventStore
  class Dispatcher < SyncScheduler
    def initialize
      warn <<~EOW
        DEPRECATION WARNING: `RubyEventStore::Dispatcher` is deprecated and will be removed in the next major release.
        Use `RubyEventStore::SyncScheduler` instead.
      EOW
    end
  end
end
