module RubyEventStore
  module ROM
    class UnitOfWork
      attr_reader :env

      def initialize(rom: ROM.env)
        @env = rom
      end

      def call(**options)
        yield(queue = [])

        commit!(options.delete(:gateway){:default}, queue, options)
      end

      def commit!(gateway, queue, **options)
        gateway = @env.container.gateways.fetch(gateway)
        gateway.transaction(options) { queue.each(&:commit) }
      end
    end
  end
end
