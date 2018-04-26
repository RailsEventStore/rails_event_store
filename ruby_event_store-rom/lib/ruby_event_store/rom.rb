require 'rom-changeset'
require 'rom-mapper'
require 'rom-repository'
require 'ruby_event_store'
require 'ruby_event_store/rom/event_repository'
require 'ruby_event_store/rom/tuple_uniqueness_error'
require 'ruby_event_store/rom/unit_of_work'
require 'ruby_event_store/rom/version'

module RubyEventStore
  module ROM
    class Env
      attr_accessor :container
  
      def initialize(container)
        @container = container
  
        container.register(:unique_violation_error_handlers, Set.new)
        container.register(:not_found_error_handlers, Set.new)
        container.register(:logger, Logger.new(STDOUT).tap { |logger| logger.level = Logger::WARN })
      end

      def logger
        container[:logger]
      end

      def unit_of_work(&block)
        options = container[:unit_of_work_options].dup
        options.delete(:class){UnitOfWork}.new(rom: self).call(**options, &block)
      end

      def register_unit_of_work_options(options)
        container.register(:unit_of_work_options, options)
      end
  
      def register_error_handler(type, handler)
        container[:"#{type}_error_handlers"] << handler
      end
  
      def handle_error(type, *args, swallow: [])
        yield
      rescue => ex
        begin
          container[:"#{type}_error_handlers"].each{ |h| h.call(ex, *args) }
          raise ex
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
        elsif database_uri.nil?
          raise ArgumentError.new('Missing database URI argument or DATABASE_URL environment variable')
        else
          Env.new ::ROM.container(adapter_name, database_uri, &block)
        end
      end
  
      def setup(*args, &block)
        configure(*args) do |config|
          setup_defaults(config)
          block.call(config) if block
        end.tap(&method(:configure_defaults))
      end

    private
      
      def setup_defaults(config)
        require_relative 'rom/repositories/stream_entries'
        require_relative 'rom/repositories/events'
        
        config.register_mapper(ROM::Mappers::EventToSerializedRecord)
        config.register_mapper(ROM::Mappers::StreamEntryToSerializedRecord)

        find_adapters(config.environment.gateways).each do |adapter|
          adapter.setup(config)
        end
      end

      def configure_defaults(env)
        env.register_error_handler :not_found, -> (ex, event_id) {
          case ex
          when ::ROM::TupleCountMismatchError
            raise EventNotFound.new(event_id)
          end
        }

        find_adapters(env.container.gateways).each do |adapter|
          adapter.configure(env)
        end
      end

      def find_adapters(gateways)
        # Setup for each kind of gateway class
        gateways.values.map(&:class).uniq.map do |klass|
          constant = klass.name.split('::')[1].to_sym

          next unless RubyEventStore::ROM.constants.include?(constant)

          RubyEventStore::ROM.const_get(constant)
        end
      end
    end
  end
end
