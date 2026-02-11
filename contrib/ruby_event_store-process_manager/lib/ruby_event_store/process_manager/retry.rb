# frozen_string_literal: true

module RubyEventStore
  module ProcessManager
    module Retry
      def with_retry
        yield
      rescue RubyEventStore::WrongExpectedEventVersion
        yield
      end
    end
  end
end
