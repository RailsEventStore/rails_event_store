module RubyEventStore
  module ROM
    class UnitOfWork
      def self.perform(gateway)
        queue = []
        yield(queue)
        gateway.transaction(savepoint: true) { queue.each(&:commit) }
      end
    end
  end
end
