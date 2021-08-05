module RubyEventStore
  module ROM
    class Env
      include Dry::Container::Mixin

      attr_accessor :rom_container

      def initialize(rom_container)
        @rom_container = rom_container
      end
    end
  end
end