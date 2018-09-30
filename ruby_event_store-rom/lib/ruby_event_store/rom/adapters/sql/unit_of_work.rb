module RubyEventStore
  module ROM
    module SQL
      class UnitOfWork < ROM::UnitOfWork
        def commit!(gateway, changesets, **options)
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
          options.merge!(
            retry_on: Sequel::SerializationFailure,
            before_retry: -> (num, ex) {
              env.logger.warn("RETRY TRANSACTION [#{self.class.name} => #{ex.class.name}] #{ex.message}")
            }
          )
  
          gateway.transaction(options) do
            changesets.each do |changeset|
              case changeset
              when ROM::Repositories::Events::BatchUpdate
                changeset.commit
              else
                changeset.relation.multi_insert(changeset.to_a)
              end
            end
          end
        end
      end
    end
  end
end
