module RubyEventStore
  module ROM
    module SQL
      class UnitOfWork < ROM::UnitOfWork
        def commit!(gateway, queue, **options)
          if gateway.connection.database_type =~ /mysql/
            env.lock.synchronize { super }
          else
            super
          end
        end
      end
    end
  end
end
