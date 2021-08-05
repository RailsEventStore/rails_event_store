module RubyEventStore
  module ROM
    class Env
      include Dry::Container::Mixin

      attr_accessor :rom_container

      def initialize(rom_container)
        @rom_container = rom_container

        register(:unique_violation_error_handlers, Set.new)
        register(:not_found_error_handlers, Set.new)
        register(:logger, Logger.new(STDOUT).tap { |logger| logger.level = Logger::WARN })
      end

      def logger
        resolve(:logger)
      end

      def unit_of_work(&block)
        options = resolve(:unit_of_work_options).dup
        options.delete(:class) { UnitOfWork }.new(rom: self).call(**options, &block)
      end

      def register_unit_of_work_options(options)
        register(:unit_of_work_options, options)
      end

      def register_error_handler(type, handler)
        resolve(:"#{type}_error_handlers") << handler
      end

      def handle_error(type, *args)
        yield
      rescue StandardError => e
        resolve(:"#{type}_error_handlers").each { |h| h.call(e, *args) }
        raise e
      end
    end
  end
end