# frozen_string_literal: true

require 'rom-changeset'
require 'rom-repository'
require 'ruby_event_store'
require 'ruby_event_store/rom/types'
require 'ruby_event_store/rom/event_repository'
require 'ruby_event_store/rom/changesets/create_events'
require 'ruby_event_store/rom/changesets/update_events'
require 'ruby_event_store/rom/changesets/create_stream_entries'
require 'ruby_event_store/rom/tuple_uniqueness_error'
require 'ruby_event_store/rom/unit_of_work'
require 'ruby_event_store/rom/version'

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

      def handle_error(type, *args, swallow: [])
        yield
      rescue StandardError => e
        begin
          resolve(:"#{type}_error_handlers").each { |h| h.call(e, *args) }
          raise e
        rescue *swallow
          # swallow
        end
      end
    end

    class << self
      # Set to a default instance
      attr_accessor :env

      def configure(adapter_name, database_uri = ENV['DATABASE_URL'], &block)
        if adapter_name.is_a?(::ROM::Configuration)
          # Call config block manually
          Env.new ::ROM.container(adapter_name.tap(&block), &block)
        else
          Env.new ::ROM.container(adapter_name, database_uri, &block)
        end
      end

      def setup(*args, &block)
        configure(*args) do |config|
          setup_defaults(config)
          yield(config) if block
        end.tap(&method(:configure_defaults))
      end

      private

      def setup_defaults(config)
        require_relative 'rom/repositories/stream_entries'
        require_relative 'rom/repositories/events'

        config.register_mapper(Mappers::StreamEntryToSerializedRecord)
        config.register_mapper(Mappers::EventToSerializedRecord)

        find_adapters(config.environment.gateways).each do |adapter|
          adapter.setup(config)
        end
      end

      def configure_defaults(env)
        env.register_error_handler :not_found, lambda { |ex, event_id|
          case ex
          when ::ROM::TupleCountMismatchError
            raise EventNotFound, event_id
          end
        }

        find_adapters(env.rom_container.gateways).each do |adapter|
          adapter.configure(env)
        end
      end

      def find_adapters(gateways)
        # Setup for each kind of gateway class
        gateways.values.map(&:class).map do |klass|
          const_get(klass.name.split('::').fetch(1))
        end
      end
    end
  end
end
