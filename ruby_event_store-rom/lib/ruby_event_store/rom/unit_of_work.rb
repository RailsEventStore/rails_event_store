# frozen_string_literal: true

module RubyEventStore
  module ROM
    class UnitOfWork
      attr_reader :env

      def initialize(rom: ROM.env)
        @env = rom
      end

      def call(**options)
        gateway = @env.rom_container.gateways.fetch(options.delete(:gateway) { :default })

        yield(changesets = [])

        commit!(gateway, changesets, **options)
      end

      def commit!(gateway, changesets, **options)
        gateway.transaction(options) { changesets.each(&:commit) }
      end
    end
  end
end
