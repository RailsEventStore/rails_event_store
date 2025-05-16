# frozen_string_literal: true

module RubyEventStore
  module ROM
    class UnitOfWork
      def initialize(gateway)
        @gateway = gateway
      end

      def call
        yield(changesets = [])
        @gateway.transaction(
          savepoint: true,
          # See: https://github.com/jeremyevans/sequel/blob/master/doc/transactions.rdoc
          #
          # Committing changesets concurrently causes MySQL deadlocks
          # which are not caught and retried by Sequel's built-in
          # :retry_on option. This appears to be a result of how ROM
          # handles exceptions which don't bubble up so that Sequel
          # can retry transactions with the :retry_on option when there's
          # a deadlock.
          #
          # This is exacerbated by the fact that changesets insert multiple
          # tuples with individual INSERT statements because ROM specifies
          # to Sequel to return a list of primary keys created. The likelihood
          # of a deadlock is reduced with batched INSERT statements.
          #
          # For this reason we need to manually insert changeset records to avoid
          # MySQL deadlocks or to allow Sequel to retry transactions
          # when the :retry_on option is specified.
          retry_on: Sequel::SerializationFailure,
          before_retry:
            lambda do |_num, ex|
              env.logger.warn("RETRY TRANSACTION [#{self.class.name} => #{ex.class.name}] #{ex.message}")
            end,
        ) { changesets.each(&:commit) }
      end
    end
  end
end
