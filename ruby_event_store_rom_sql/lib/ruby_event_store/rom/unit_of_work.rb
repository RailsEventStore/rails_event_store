module RubyEventStore
  module ROM
    class UnitOfWork
      def self.perform(rom: ROM.env)
        queue = []
        yield(queue)
        rom.gateways[:default].transaction(savepoint: true) { queue.each(&:commit) }
      end
    end
  end
end
