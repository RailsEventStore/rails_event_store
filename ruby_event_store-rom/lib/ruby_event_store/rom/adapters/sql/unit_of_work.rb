module RubyEventStore
  module ROM
    module SQL
      class UnitOfWork < ROM::UnitOfWork
        def commit!(gateway, changesets, **options)
          # Committing changesets concurrently causes MySQL deadlocks
          # which are not caught and retired by Sequel's built-in
          # :retry_on option.
          #
          # gateway.transaction(options) { changesets.each(&:commit) }
          
          return super unless gateway.connection.database_type == :mysql
  
          # We need to manually insert changeset records to avoid
          # MySQL deadlocks or to allow Sequel to retry transactions
          # when the :retry_on option is specified.
          #
          # This appears to be a result of how ROM handles exceptions
          # which doesn't bubble up so that Sequel retries transactions
          # with the :retry_on option when there's a deadlock.
          gateway.transaction(options) do
            changesets.each do |changeset|
              changeset.relation.multi_insert(changeset.to_a)
            end
          end
        end
      end
    end
  end
end
