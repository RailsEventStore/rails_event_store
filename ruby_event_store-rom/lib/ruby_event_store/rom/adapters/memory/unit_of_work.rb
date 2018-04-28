module RubyEventStore
  module ROM
    module Memory
      class UnitOfWork < ROM::UnitOfWork
        def self.mutex
          @mutex ||= Mutex.new
        end

        def commit!(gateway, changesets, **options)
          self.class.mutex.synchronize do
            committed = []
            
            while changesets.size > 0
              changeset = changesets.shift

              begin
                relation = env.container.relations[changeset.relation.name]

                case changeset
                when ROM::Repositories::Events::Create
                  relation.by_pk(changeset.to_a.map{ |e| e[:id] }).each do |tuple|
                    raise TupleUniquenessError.for_event_id(tuple[:id])
                  end
                when ROM::Repositories::StreamEntries::Create
                  changeset.to_a.each do |tuple|
                    relation.send(:verify_uniquness!, tuple)
                  end
                else
                  raise ArgumentError, 'Unknown changeset'
                end

                committed << [changeset, relation]

                changeset.commit
              rescue => ex
                committed.reverse.each do |changeset, relation|
                  relation
                    .restrict(id: changeset.to_a.map { |e| e[:id] })
                    .command(:delete, result: :many).call
                end
                
                raise
              end
            end
          end
        end
      end
    end
  end
end
