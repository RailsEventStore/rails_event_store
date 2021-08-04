# frozen_string_literal: true

module RubyEventStore
  module ROM
    class UnitOfWork
      def initialize(rom: ROM.env)
        @gateway = rom.rom_container.gateways.fetch(:default)
      end

      def call(**options)
        yield(changesets = [])
        @gateway.transaction(options) { changesets.each(&:commit) }
      end
    end
  end
end
