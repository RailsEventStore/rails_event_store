module RubyEventStore
  module ROM
    class Env
      include Dry::Container::Mixin

      attr_accessor :rom_container

      def initialize(rom_container)
        @rom_container = rom_container
      end

      def unit_of_work(&block)
        options = resolve(:unit_of_work_options).dup
        options.delete(:class) { UnitOfWork }.new(rom: self).call(**options, &block)
      end

      def register_unit_of_work_options(options)
        register(:unit_of_work_options, options)
      end
    end
  end
end