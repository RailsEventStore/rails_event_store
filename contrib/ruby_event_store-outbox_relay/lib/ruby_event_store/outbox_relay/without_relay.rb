# frozen_string_literal: true

module RubyEventStore
  module OutboxRelay
    # A thread-local scope EventRepositoryExtension#insert_hash reads to decide
    # whether the row being inserted needs outbox delivery.
    #
    # Client#append and Client#publish both funnel through the same
    # #append_to_stream, so EventRepositoryExtension has no way on its own to
    # tell apart an #append insert (documented as "persists without notifying
    # any subscribed handlers") from a #publish one. ClientExtension's #append
    # override opens this scope around its otherwise unmodified super call, so
    # insert_hash can mark that row as not needing relay delivery.
    module WithoutRelay
      ACTIVE = Concurrent::ThreadLocalVar.new(false)
      private_constant :ACTIVE

      # @yield the block to run with relay delivery suppressed for every row
      #   inserted within it
      def self.call
        previous = ACTIVE.value
        ACTIVE.value = true
        yield
      ensure
        ACTIVE.value = previous
      end

      # @return [Boolean]
      def self.active?
        ACTIVE.value
      end
    end
  end
end
