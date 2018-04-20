module RubyEventStore
  module ROM
    module Memory
      class UnitOfWork < RubyEventStore::ROM::UnitOfWork
        def commit!(gateway, queue, options = {})
          completed = []
          
          while queue.size > 0
            completed << queue.shift

            begin
              completed.last.commit
            rescue => ex
              completed.reverse.each do |item|
                item.relation.command(:delete, result: :many).call
              end
              raise
            end
          end
        end
      end
    end
  end
end
