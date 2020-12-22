# frozen_string_literal: true

require 'ruby_event_store/rom'
require 'rom/memory'
require_relative 'adapters/memory/unit_of_work'
require_relative 'adapters/memory/relations/events'
require_relative 'adapters/memory/relations/stream_entries'
require_relative 'adapters/memory/changesets/create_events'
require_relative 'adapters/memory/changesets/update_events'
require_relative 'adapters/memory/changesets/create_stream_entries'

module RubyEventStore
  module ROM
    module Memory
      class << self
        def fetch_next_id
          @last_id ||= 0
          @mutex ||= Mutex.new
          @mutex.synchronize { @last_id += 1 }
        end

        def setup(config)
          config.register_relation Relations::Events
          config.register_relation Relations::StreamEntries
        end

        def configure(env)
          env.register_unit_of_work_options(class: UnitOfWork)

          env.register_error_handler :unique_violation, lambda { |ex|
            case ex
            when TupleUniquenessError
              raise EventDuplicatedInStream if ex.message =~ /event_id/

              raise WrongExpectedEventVersion
            end
          }
        end
      end

      class SpecHelper
        attr_reader :env

        def initialize
          @env = ROM.setup(:memory)
        end

        def run_lifecycle
          yield
        ensure
          drop_gateway_schema
        end

        def gateway
          env.rom_container.gateways.fetch(:default)
        end

        def drop_gateway_schema
          gateway.connection.data.values.each { |v| v.data.clear }
        end

        def close_gateway_connection
          gateway.disconnect
        end

        def gateway_type?(name)
          name == :memory
        end

        def has_connection_pooling?
          false
        end

        def supports_upsert?
          true
        end

        def supports_concurrent_any?
          true
        end

        def supports_concurrent_auto?
          true
        end

        def supports_binary?
          !ENV['DATA_TYPE'] =~ /json/
        end

        def rescuable_concurrency_test_errors
          []
        end

        def cleanup_concurrency_test
        end
      end
    end
  end
end
