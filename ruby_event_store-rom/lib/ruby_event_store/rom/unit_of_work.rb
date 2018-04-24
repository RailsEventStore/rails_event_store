module RubyEventStore
  module ROM
    class UnitOfWork
      attr_reader :env

      def initialize(rom: ROM.env)
        @env = rom
      end

      def call(**options)
        gateway = @env.container.gateways.fetch(options.delete(:gateway){:default})

        yield(queue = [])

        commit!(gateway, queue, options)
      end

      def commit!(gateway, queue, **options)
        gateway.connection.transaction(options) { queue.each(&:commit) }
      end
    end
  end
end
